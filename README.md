# skills

A collection of agent skills and Claude Code hooks.

```
skills/        ← reusable agent skills (installed via npx)
hooks/         ← Claude Code hooks, symlinked from ~/.claude/hooks/
```

## Skills

Install with:

```bash
npx skills add ekinertac/skills/skills/tweak-panel
npx skills add ekinertac/skills/skills/macos-notarize
npx skills add ekinertac/skills/skills/pre-mortem
npx skills add ekinertac/skills/skills/html-effectiveness
```

### tweak-panel

Skip the "a bit more / a bit less" loop. Ask the agent to build a floating control panel inside your running app, tune the values yourself, then paste them back to apply.

[→ View skill](./skills/tweak-panel/SKILL.md)

---

### macos-notarize

Full guide for signing and notarizing a macOS `.app` for distribution outside the App Store. Covers Developer ID codesigning, `notarytool` submission, stapling, GitHub Actions CI setup (including certificate import and secrets), and diagnosis of every common Apple notarization error.

[→ View skill](./skills/macos-notarize/SKILL.md)

---

### pre-mortem

Assume the plan already failed 6 months from now — then work backward. Spawns parallel sub-agents across three mandatory death categories (technical, market, founder), each writing as your future self. Synthesizes into a ranked report with the silent assumption exposed, a concrete revised plan, and a "this week" action list. Credit: [@itsolelehmann](https://x.com/itsolelehmann)

[→ View skill](./skills/pre-mortem/SKILL.md)

---

### html-effectiveness

Turn document-shaped requests into single shareable HTML artifacts instead of walls of markdown — for plans, PR reviews, status reports, design systems, custom editors, and more. Routes the request to one of 19 use-case templates drawn from the demos in `references/`, composes the artifact from a small library of HTML building blocks (`patterns.md`), and links a shared `styles.css` so output stays compact. Inspired by [@trq212](https://x.com/trq212)'s post on the unreasonable effectiveness of HTML.

[→ View skill](./skills/html-effectiveness/SKILL.md)

## Hooks

Claude Code hooks. Each script lives here under git and is symlinked from `~/.claude/hooks/<name>` so Claude Code's hook resolver picks them up. Install with:

```bash
ln -s ~/Code/skills/hooks/auto-title.sh     ~/.claude/hooks/auto-title.sh
ln -s ~/Code/skills/hooks/session-digest.sh ~/.claude/hooks/session-digest.sh
```

Then register each in `~/.claude/settings.json` under the right event (see each script's header comment for the event it expects).

### auto-title.sh

Runs on `UserPromptSubmit`. The first time you submit a prompt in a fresh session, generates a 5–10 word title via `claude -p` (haiku alias, `--no-session-persistence`) and appends a `{"type":"custom-title",...}` event into the transcript — the same shape `/rename` writes manually. Idempotent (skips if a custom-title is already present). Backgrounds the title-gen call so prompt submission isn't blocked.

### session-digest.sh

Runs on `SessionEnd`. Generates a markdown digest of the session and writes it into the Tolaria vault under `wiki/sessions/`. Captures the conversation arc (TL;DR, topics, mental models, decisions, pushback, gotchas, open threads) so a future session 6 months from now can recover context that would otherwise vanish on `/clear` or exit. Backgrounded with `disown` so SessionEnd doesn't block UI exit.
