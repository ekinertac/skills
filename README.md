# skills

A collection of agent skills for Claude Code and other AI agents.

## Install

```bash
npx skills add ekinertac/skills/tweak-panel
npx skills add ekinertac/skills/macos-notarize
```

## Skills

### tweak-panel

Skip the "a bit more / a bit less" loop. Ask the agent to build a floating control panel inside your running app, tune the values yourself, then paste them back to apply.

[→ View skill](./tweak-panel/SKILL.md)

---

### macos-notarize

Full guide for signing and notarizing a macOS `.app` for distribution outside the App Store. Covers Developer ID codesigning, `notarytool` submission, stapling, GitHub Actions CI setup (including certificate import and secrets), and diagnosis of every common Apple notarization error.

[→ View skill](./macos-notarize/SKILL.md)
