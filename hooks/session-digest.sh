#!/usr/bin/env bash
# session-digest.sh
#
# Responsibility: Run on Claude Code SessionEnd. Generates a markdown digest of
# the session and writes it into the Tolaria vault at
# /Users/ekinertac/Code/tolaria-vault/wiki/sessions/.
#
# Where it fits: User-level hook configured in ~/.claude/settings.json under
# the SessionEnd event. Pairs with the existing user-level hooks
# (rtk-rewrite.sh, context-mode-cache-heal.mjs) — same hooks dir, same wiring
# style. The digest enables cross-session memory: future Claude sessions read
# wiki/sessions/* for context that would otherwise vanish on /clear or exit.
#
# How it relates: Reads the JSONL transcript Claude Code already writes to
# ~/.claude/projects/<encoded-cwd>/<session-id>.jsonl. Spawns a detached
# `claude -p` headless call (cheap Haiku model) to compile the digest. The
# heavy work runs in the background so SessionEnd does not block UI exit.
# The vault path is hard-coded — see project_tolaria_vault.md memory.
#
# Constraints:
#   - Skips sessions with < 10 transcript lines (noise filter).
#   - Skips silently if `claude` CLI or `jq` missing.
#   - Failures log to /tmp/session-digest-*.log; never block the user.
#   - Background process detaches with `disown` so terminal exit does not kill it.

set -uo pipefail

# RECURSION GUARD: this hook spawns `claude -p` which is itself a Claude Code
# session and will trigger SessionEnd when it finishes. Without this guard the
# hook fan-outs into an infinite loop (credit-limit errors do not break it —
# they just speed it up). Inherited env var stops nested invocations.
if [ "${TOLARIA_DIGEST_RUNNING:-0}" = "1" ]; then
  exit 0
fi

VAULT="/Users/ekinertac/Code/tolaria-vault"
SESSIONS_DIR="$VAULT/sessions"
LOG_DIR="/tmp"
MIN_TRANSCRIPT_LINES=10
MODEL="claude-haiku-4-5-20251001"

command -v claude >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0

payload="$(cat)"
transcript_path="$(echo "$payload" | jq -r '.transcript_path // empty')"
session_id="$(echo "$payload" | jq -r '.session_id // empty')"
cwd="$(echo "$payload" | jq -r '.cwd // empty')"
reason="$(echo "$payload" | jq -r '.reason // "unknown"')"

[ -z "$transcript_path" ] && exit 0
[ ! -f "$transcript_path" ] && exit 0

turn_count="$(wc -l < "$transcript_path" | tr -d ' ')"
[ "$turn_count" -lt "$MIN_TRANSCRIPT_LINES" ] && exit 0

mkdir -p "$SESSIONS_DIR"

timestamp="$(date +%Y-%m-%d-%H%M)"
project_slug="$(basename "$cwd" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9' '-' | sed -E 's/-+/-/g; s/^-//; s/-$//')"
[ -z "$project_slug" ] && project_slug="unknown"

# DEDUPE BY SESSION_ID: `claude --continue` / `--resume` reuses the same
# session_id but the hook fires on every exit. Without dedupe, one logical
# session produces N files. Naming by short-session-id makes the path
# deterministic — re-running the hook simply overwrites the prior digest with
# a fresh summary that includes the newly continued turns.
#
# Fallback: if session_id is empty (manual fire, malformed payload), fall back
# to timestamp-based naming so we never collide with real sessions.
sid_short="$(printf '%s' "$session_id" | tr -cd 'a-zA-Z0-9-' | cut -c1-8)"
if [ -n "$sid_short" ]; then
  out_file="$SESSIONS_DIR/${sid_short}-${project_slug}.md"
else
  out_file="$SESSIONS_DIR/${timestamp}-${project_slug}.md"
fi
log_file="$LOG_DIR/session-digest-${timestamp}.log"

prompt="Read the Claude Code session transcript at: $transcript_path

Write a markdown digest that captures BOTH the narrative AND the artifacts of the session. Caveman style — drop articles/filler. Output ONLY the markdown content, no preamble.

Mental frame: a future Claude session will read this 6 months from now to recover context. Conversation matters as much as code. Capture the THINKING, not just the diff. Pure code-review style misses why we chose what we chose.

For non-coding sessions (research, brainstorming, planning), narrative sections dominate. For coding sessions, all sections balance. Omit any section that would be empty — do not pad with placeholders.

Frontmatter shape (keep order):
---
type: Session
title: \"<short descriptive title, max 80 chars>\"
date: $(date +%Y-%m-%d)
time: \"$(date +%H:%M)\"
project: \"[[$project_slug]]\"
project_path: $cwd
session_id: $session_id
end_reason: $reason
turns: $turn_count
---

# <same descriptive title as in frontmatter>

## TL;DR
2-3 sentences. The arc: what user came in with, what changed, what they walked out with.

## Topics discussed
Bullets. Each topic + 1-2 sentences on what was explored. Include topics that did not produce code (research, comparisons, framing). The conversation itself is content.

## Mental models established
Frameworks, abstractions, framings, or analogies the user adopted (or rejected) during the session. Quote the user's own phrasings when memorable. Each entry: name → 1-line definition → why it matters going forward.

## Decisions made
Each: decision + why + what was REJECTED in favor of it. Rejections capture taste and constraints — keep them.

## Pushback / pivots
Moments the user redirected, rejected an approach, or changed scope. What did they push back against, and what was the reasoning? These are the highest-signal lines in the transcript.

## Built or changed
Files/scripts/configs created or modified. Absolute path + 1-line role. Only paths that appear verbatim in the transcript — do not invent.

## Gotchas / debug threads
Bugs hit, dead-ends, surprises. file:line citation only when the path appears verbatim. Include the symptom AND the root cause.

## Open threads
Anything user said \"later\", \"todo\", \"hold for now\", or that was deferred without resolution. Be explicit about what is deferred and why.

## References cited
URLs, papers, gists, repos that came up. Include all external links from the transcript. One per line: [title](url) — context.

Save the markdown to: $out_file
Use Write tool. Do not ask for confirmation."

(
  # Force subscription auth: any ANTHROPIC_API_KEY in env hijacks the
  # CLI to console billing (which may be empty). User is on Pro/Max,
  # subscription is the intended billing path for digest calls.
  unset ANTHROPIC_API_KEY ANTHROPIC_AUTH_TOKEN CLAUDE_API_KEY
  TOLARIA_DIGEST_RUNNING=1 \
  claude -p "$prompt" \
    --model "$MODEL" \
    --allowedTools "Read,Write,Bash,Glob,Grep" \
    --dangerously-skip-permissions \
    > "$log_file" 2>&1
) &
disown

exit 0
