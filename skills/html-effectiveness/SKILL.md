---
name: html-effectiveness
description: Use when the user asks for HTML output — "make an HTML file", "as an HTML artifact", "export to HTML", or any request whose output is an .html file. Produces artifacts in the Birchline visual language (ivory/clay/oat palette, serif headings, mono eyebrows) by linking styles.css and composing patterns from patterns.md and structural cues from references/.
---

<!--
File: html-effectiveness/SKILL.md
Role: Entry point for the html-effectiveness skill. Loaded first; tells
      Claude when the skill is in scope, the rules every artifact must
      follow, and which reference demo to read for which use case.
Read alongside: styles.css (linked, not inlined), patterns.md (always),
      references/NN-*.html (only when the use-case router matches).
-->

# html-effectiveness

Turn document-shaped requests into single self-contained `.html` artifacts that look like the demos in `references/`. Match the post's spirit (give the user something they'd actually read and share) by leaning on a fixed visual identity and a small library of recurring building blocks.

## Why HTML over markdown

Information density (tables, SVG, real layout). Sharing (open in any browser, link to a host). Two-way interaction (sliders, drag, copy-back exports). Joy. Markdown is fine for terse internal output; HTML is for anything you want a person to read once.

## Hard rules

- **Two files.** Output is an `.html` file plus a sibling `./styles.css`. No JS or font CDN dependencies — but the stylesheet is intentionally external to save tokens. The pair travels together (zip / upload the folder).
- **Open with `<!doctype html>`**, set `<html lang="en">` and a viewport meta.
- **Link `styles.css`.** Add `<link rel="stylesheet" href="./styles.css">` to `<head>`. Do not inline CSS, do not redeclare classes. Before writing the artifact, verify a `styles.css` exists in the output directory; if it does not, copy it from this skill's own folder (the directory that contains this SKILL.md and styles.css).
- **Read before writing.** On every activation, read `styles.css` and `patterns.md` end-to-end so you know which classes and snippets exist. If the use case matches a row in the router below, also read the named demo.
- **Editors must export.** Any artifact that lets the user edit/sort/toggle/tune ends with a "Copy as X" button (see `patterns.md` §9) that turns UI state into pasteable text.
- **Mobile-responsive** by default. The demos all are; a `@media (max-width: 720px)` breakpoint is the floor.
- **No emojis** unless the user asks. No filler text — fill with realistic, specific content.
- **Default filename:** `<topic-slug>.html` in the current working directory unless the user specifies otherwise.

## Use-case router

When a row matches the user's intent, read the named demo as a structural reference, then compose the artifact from `styles.css` + `patterns.md`.

| User wants… | Read demo | Patterns to use |
|---|---|---|
| Compare 2–6 options/approaches side-by-side | `01-exploration-code-approaches.html` or `02-exploration-visual-designs.html` | card-grid, eyebrow-header |
| Implementation plan / spec | `16-implementation-plan.html` | sec-head, summary-strip, prompt-box, inline-svg-figure |
| Annotated PR / code review | `03-code-review-pr.html` | sec-head, prompt-box |
| PR writeup for reviewers | `17-pr-writeup.html` | sec-head, summary-strip |
| Code/module understanding | `04-code-understanding.html` | inline-svg-figure, sec-head |
| Design system / token reference | `05-design-system.html` | swatch, sec-head |
| Component variants on one sheet | `06-component-variants.html` | card-grid, sec-head |
| Animation prototype with knobs | `07-prototype-animation.html` | slider-row, copy-as-X-button |
| Click-through interaction prototype | `08-prototype-interaction.html` | card-grid, copy-as-X-button |
| Slide deck (arrow-key navigation) | `09-slide-deck.html` | eyebrow-header |
| SVG illustrations / figure sheet | `10-svg-illustrations.html` | inline-svg-figure |
| Weekly status report | `11-status-report.html` | summary-strip, sec-head |
| Incident timeline / post-mortem | `12-incident-report.html` | sec-head, inline-svg-figure |
| Flowchart / pipeline diagram | `13-flowchart-diagram.html` | inline-svg-figure |
| How-a-feature-works explainer | `14-research-feature-explainer.html` | sec-head, prompt-box |
| Concept explainer with live demo | `15-research-concept-explainer.html` | inline-svg-figure, slider-row |
| Triage / kanban editor | `18-editor-triage-board.html` | kanban-column, copy-as-X-button |
| Form-based config editor | `19-editor-feature-flags.html` | sec-head, copy-as-X-button |
| Side-by-side / split-pane editor | `20-editor-prompt-tuner.html` | copy-as-X-button |

If nothing in this table fits, improvise from `styles.css` and `patterns.md` directly. The skill is a router, not a cage.

## Process

1. **Identify the use case.** Match the user's request to a row in the router, or recognize it doesn't match.
2. **Read.** `styles.css` and `patterns.md` always. The matched demo if there is one.
3. **Sketch.** Decide what sections, what data, what export button (if editor) before writing markup. Don't think in CSS yet — that's already in `styles.css`.
4. **Generate.** Produce one `.html` file inline. Ensure `./styles.css` exists in the output directory (copy from the skill folder if missing). Reference it via `<link>` in `<head>`. Compose body from `patterns.md` snippets, adapted to the user's content. Fill with specific, realistic data — no `Lorem ipsum`, no `<!-- TODO -->`.
5. **Offer to open.** After writing, suggest `open <file>` (macOS) so the user can view it.

## Anti-patterns

- Bare browser-default styling (no `styles.css` linked).
- ASCII diagrams when `inline-svg-figure` would do.
- Linking external fonts, scripts, or CDN CSS — only `./styles.css` is the permitted external stylesheet.
- Editor artifact with no copy/export button.
- Fake or padded content to make the page look fuller. Better short and specific than long and vague.
- Re-declaring `styles.css` classes in the artifact's local `<style>`. Local CSS is for layout-specific exceptions only.
