#!/usr/bin/env bash
# auto-title.sh
#
# Responsibility: Run on Claude Code UserPromptSubmit. Auto-generates a
# 5-10 word session title from the user's first prompt and writes it as a
# {"type":"custom-title","customTitle":...,"sessionId":...} event into the
# active session JSONL — exactly the shape /rename writes manually. cct's
# session picker surfaces these names in its row format
# (`claude/MyName — <prompt>`), so auto-titled sessions become scannable
# without ever opening claude itself to /rename them.
#
# Where it fits: User-level hook configured in ~/.claude/settings.json
# under the UserPromptSubmit event. Pairs with session-digest.sh
# (SessionEnd) — same hooks dir, same wiring style.
#
# How it relates: Reads the active session's JSONL at $transcript_path
# from the hook payload. Spawns a detached `claude -p` call with
# --no-session-persistence so the title-generation call itself does NOT
# create a parasitic entry in ~/.claude/projects/. Heavy work runs in
# the background so prompt submission isn't blocked.
#
# Constraints:
#   - Idempotent: skips if any custom-title event already exists in the
#     transcript (manual /rename or prior run of this hook).
#   - Recursion guard via CCT_AUTOTITLE_RUNNING env var. Belt-and-
#     suspenders alongside --no-session-persistence.
#   - User prompt is truncated to 1000 chars before being sent to the
#     titler — long pastes shouldn't blow up token cost.
#   - Failures log to /tmp/auto-title-*.log; never block the user.
#   - Background process detaches with disown so terminal exit doesn't
#     kill it.

set -uo pipefail

if [ "${CCT_AUTOTITLE_RUNNING:-0}" = "1" ]; then
  exit 0
fi

LOG_DIR="/tmp"
# Use the alias rather than a dated model id — `haiku` always resolves
# to the latest haiku, so this script doesn't silently break when
# Anthropic rotates the haiku version. Swap to `sonnet` or `opus` for
# better titles at higher cost.
MODEL="haiku"
MAX_USER_PROMPT_CHARS=1000

command -v claude >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0

payload="$(cat)"
transcript_path="$(echo "$payload" | jq -r '.transcript_path // empty')"
session_id="$(echo "$payload" | jq -r '.session_id // empty')"
user_prompt="$(echo "$payload" | jq -r '.prompt // empty')"

[ -z "$session_id" ] && exit 0
[ -z "$transcript_path" ] && exit 0
[ -z "$user_prompt" ] && exit 0

# Idempotent: skip if a custom-title is already there. Covers both manual
# /rename and a prior fire of this hook.
if [ -f "$transcript_path" ] && grep -q '"type":"custom-title"' "$transcript_path"; then
  exit 0
fi

# Trim long pastes — the titler only needs intent, not full content.
truncated_prompt="$(printf '%s' "$user_prompt" | cut -c1-$MAX_USER_PROMPT_CHARS)"

timestamp="$(date +%Y-%m-%d-%H%M)"
log_file="$LOG_DIR/auto-title-${timestamp}.log"

# The titler prompt — exact text the user provided. The placeholder
# token gets replaced via bash parameter expansion below; using a
# unique placeholder avoids accidental collisions with the heredoc body.
title_prompt_template=$(cat <<'PROMPT_EOF'
You are a concise session-naming assistant. Your task is to summarize the user's first input into a short, descriptive title for the conversation history.

Guidelines:
1. Ignore greetings, pleasantries, or meta-talk (e.g., "Hello," "Hi," "Can you help me with").
2. Focus exclusively on the core intent, topic, or task.
3. The title must be between 5 and 10 words long.
4. Output ONLY the title. Do not add quotes, brackets, or conversational filler.

User's input: __USER_INPUT_PLACEHOLDER__
PROMPT_EOF
)
title_prompt="${title_prompt_template//__USER_INPUT_PLACEHOLDER__/$truncated_prompt}"

(
  # Subscription auth (matches session-digest.sh): a stray API key in
  # env would route this to console billing.
  unset ANTHROPIC_API_KEY ANTHROPIC_AUTH_TOKEN CLAUDE_API_KEY

  title_output="$(
    CCT_AUTOTITLE_RUNNING=1 \
    claude -p "$title_prompt" \
      --model "$MODEL" \
      --no-session-persistence \
      2>>"$log_file"
  )"

  # Strip surrounding whitespace and a single layer of quotes/backticks
  # in case the model ignores rule 4.
  title="$(printf '%s' "$title_output" \
    | head -c 200 \
    | tr -d '\n\r' \
    | sed -E "s/^[[:space:]]*[\"'\`]?//; s/[\"'\`]?[[:space:]]*\$//")"

  if [ -z "$title" ]; then
    echo "(empty title from claude)" >> "$log_file"
    exit 0
  fi

  # Use jq to JSON-encode the title — handles embedded quotes/backslashes
  # safely, no shell-string contamination.
  event_json="$(jq -nc \
    --arg t "custom-title" \
    --arg title "$title" \
    --arg sid "$session_id" \
    '{type:$t, customTitle:$title, sessionId:$sid}')"

  printf '%s\n' "$event_json" >> "$transcript_path"
) &
disown

exit 0
