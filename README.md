# skills

A collection of agent skills.

```
<skill-name>/  ← each reusable agent skill lives at the repo root (installed via npx)
```

## Skills

Install with:

```bash
npx skills add ekinertac/skills/tweak-panel
npx skills add ekinertac/skills/macos-notarize
npx skills add ekinertac/skills/pre-mortem
npx skills add ekinertac/skills/html-effectiveness
npx skills add ekinertac/skills/visual-plan
npx skills add ekinertac/skills/recreating-amp-tones
npx skills add ekinertac/skills/cli-design
```

### recreating-amp-tones

Recreate a famous guitar/bass tone with whatever amp-sim plugins you already have. Amp-sim agnostic: discovers installed sims, finds where their (often binary, despite the `.xml`) preset files actually live, researches the real rig on tone forums (and works around their Cloudflare bot-walls), then clones-and-patches a preset that approximates it. Includes how to grab raw guitar DI stems for testing.

[→ View skill](./recreating-amp-tones/SKILL.md)

---

### tweak-panel

Skip the "a bit more / a bit less" loop. Ask the agent to build a floating control panel inside your running app, tune the values yourself, then paste them back to apply.

[→ View skill](./tweak-panel/SKILL.md)

---

### macos-notarize

Full guide for signing and notarizing a macOS `.app` for distribution outside the App Store. Covers Developer ID codesigning, `notarytool` submission, stapling, GitHub Actions CI setup (including certificate import and secrets), and diagnosis of every common Apple notarization error.

[→ View skill](./macos-notarize/SKILL.md)

---

### pre-mortem

Assume the plan already failed 6 months from now — then work backward. Spawns parallel sub-agents across three mandatory death categories (technical, market, founder), each writing as your future self. Synthesizes into a ranked report with the silent assumption exposed, a concrete revised plan, and a "this week" action list. Credit: [@itsolelehmann](https://x.com/itsolelehmann)

[→ View skill](./pre-mortem/SKILL.md)

---

### html-effectiveness

Turn document-shaped requests into single shareable HTML artifacts instead of walls of markdown — for plans, PR reviews, status reports, design systems, custom editors, and more. Routes the request to one of 19 use-case templates drawn from the demos in `references/`, composes the artifact from a small library of HTML building blocks (`patterns.md`), and links a shared `styles.css` so output stays compact. Inspired by [@trq212](https://x.com/trq212)'s post on the unreasonable effectiveness of HTML.

[→ View skill](./html-effectiveness/SKILL.md)

---

### visual-plan

Turn an implementation plan into a reviewable single-page HTML artifact instead of a wall of chat markdown — a local, dependency-free take on [BuilderIO's hosted visual-plan](https://github.com/BuilderIO/skills/tree/main/skills/visual-plan) (no MCP connector, no hosted app). Owns the planning discipline (research-first, name real files, commit to hard-to-reverse decisions, open questions at the bottom with recommended defaults, plan-as-approval-gate) and delegates all rendering to `html-effectiveness`, which composes the `plan.html` + `./styles.css` pair from its implementation-plan demo. Leads with HTML/SVG screen mockups for UI plans, stays document-only for backend/architecture.

[→ View skill](./visual-plan/SKILL.md)

---

### cli-design

Design and review command-line tools against established conventions, condensed from [clig.dev](https://clig.dev). `SKILL.md` is a scannable checklist by area (help text, stdout/stderr split, exit codes, flags vs args, TTY-aware color/output, prompts, subcommands, config precedence, env vars, naming); `reference.md` holds the full rule set with the `jq`/`git`/`docker` examples. Fires when building a new CLI or auditing an existing one's UX, and includes a fast pipe-it / force-an-error review pass.

[→ View skill](./cli-design/SKILL.md)
