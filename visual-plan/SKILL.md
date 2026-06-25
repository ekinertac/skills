---
name: visual-plan
description: Turn an implementation plan into a reviewable single-page HTML artifact instead of a wall of chat markdown. Use when the user asks to "plan", "write a plan", "make a visual plan", "plan this out", "spec this", or wants a direction reviewed and approved before any code is written — for multi-file, ambiguous, risky, architecture-heavy, data-heavy, or UI-heavy work. Renders through the html-effectiveness skill (no MCP connector, no hosted app, fully local). Skip it for trivial one-line fixes.
---

<!--
File: visual-plan/SKILL.md
Role: Entry point for the visual-plan skill. Owns the PLANNING DISCIPLINE
      (when to plan, how to research, what a good plan contains, how to gate
      handoff). It does NOT own rendering — it delegates the actual HTML
      composition to the html-effectiveness skill.
Where it fits: a local, dependency-free alternative to BuilderIO's hosted
      visual-plan. Output is a self-contained review artifact (plan.html +
      sibling ./styles.css), not a chat paragraph and not an MCP/hosted plan.
Read alongside: the html-effectiveness skill — specifically its SKILL.md,
      styles.css, patterns.md, and references/16-implementation-plan.html.
      visual-plan invokes html-effectiveness; it never re-declares its CSS or
      duplicates its rendering rules.
Key decision: rendering is fully owned by html-effectiveness so the two skills
      stay decoupled — this file only decides WHAT goes in the plan, never HOW
      it is styled.
-->

# visual-plan

Turn the plan an agent would normally type into chat into a scannable, shareable HTML document a human can read once and approve. Same discipline as a strong Claude/Codex implementation plan — outcome-first, grounded in real files, decisions committed — but the deliverable is a `plan.html` artifact rendered through the **html-effectiveness** skill, with zero external dependencies (no MCP connector, no hosted app, no network).

This skill owns the **planning discipline**. It does not render anything itself — when it is time to produce the file, it **invokes the html-effectiveness skill** and lets that skill compose the HTML from its `styles.css` + `patterns.md`. Keep the two concerns separate: decide *what* the plan says here, let html-effectiveness decide *how* it looks.

## When to use

Build a visual plan whenever the direction would be better as a reviewable artifact than a chat paragraph: multi-file, ambiguous, long-running, risky, architecture-heavy, data-heavy, or UI-heavy work, or when the user needs to react to a direction before you implement. Also use it to upgrade an existing pasted/Markdown plan into a richer review surface.

**Gate it.** Skip the plan for truly trivial, unambiguous work — typos, one-line fixes, a single well-specified function, anything whose diff you could describe in one sentence — and just make the change. Never pad a plan with filler and never ship a single-step plan.

## Plan discipline

These are the rules that make the plan worth reviewing. They are adapted from the hosted visual-plan discipline but carry no dependency on it.

- **Research before you draft.** Read the real files, actions, schema, and patterns first. Name actual files, symbols, and data shapes instead of inventing them. Check existing code before proposing new endpoints/helpers, and prefer named helpers over raw calls. Delegate wide exploration to a sub-agent when the surface is large.
- **Lead with reuse.** For each step, name what it *reuses* — existing actions, schema, components, helpers — before what it *adds*, so the plan explains the genuinely new delta instead of redescribing what already exists.
- **Decide the hard-to-reverse bets first.** Call out decisions that are expensive to undo once data or callers depend on them — wire format, public ids, data-model shape, auth and ownership boundaries — and get those right in the plan even if most of the feature ships later. Then scope to the smallest first cut that proves the approach without foreclosing it, stating what is in and what is explicitly deferred.
- **Keep examples at the right altitude.** When the idea is a broad framework or product change, separate the reusable core from the motivating examples and adapters. Use examples to make the plan legible, but label them as examples unless they are the whole requested scope.
- **Planning is read-only.** Make no source edits while researching or drafting the plan. Start editing only after the user approves the direction.
- **Clarify vs. assume.** Do not ask *how* to build it — explore and present the approach in the plan. Ask a clarifying question only when an ambiguity would change the design and you cannot resolve it from the code; batch 2–4 high-leverage questions before finalizing. Otherwise state the assumption explicitly and proceed, and keep anything unresolved in the bottom Open Questions section.
- **The plan stands alone.** If the user pasted or already has a plan, treat it as source material but write the published plan as a clean standalone proposal. Avoid revision language ("preserve the prior plan", "unlike the previous version", "this revision changes…"). A reader who never saw the chat should understand it.
- **The plan is the approval gate.** After rendering it, present it, name which files/areas the work touches, and ask for sign-off before you write code. Presenting the plan and requesting approval *is* the approval step — do not ask a separate "does this look good?" question.

## Visual surface choice

Decide the surface before rendering. Do not add visual chrome by default.

- **UI / product plans → lead with mockups.** Compose 1–4 HTML/SVG mockups of the key screens or states first (default view, the changed state, an overflow/popover, loading or error), then the document below. Use html-effectiveness's `card-grid` to lay states side by side and `inline-svg-figure` for screen sketches. Keep product screens **pure** — real labels, real counts, real button text; no architecture arrows, file contracts, or repo names baked inside the screen. Put those in the document body. When the task changes an existing screen, reproduce the current layout first, then show only the delta.
- **Backend / architecture / data / refactor plans → document-only.** No app mockups. Use one `inline-svg-figure` diagram per recommendation or decision when relationships need a spatial explanation (prefer layered diagrams, before/after panels, or grouped regions over a single left-to-right chain). The document itself is the review surface.
- **No visual surface** for copy-only or otherwise non-visual plans. A strong document is the artifact.

## Process

1. **Gate and research.** Confirm the work warrants a plan (above). Read the real code; delegate wide exploration to a sub-agent if useful. Gather actual file names, symbols, and data shapes. If a source plan exists, gather its exact text rather than inventing it.
2. **Choose the surface** (above) and sketch the document skeleton (below) — what sections, what data, which decisions are settled vs. open — before writing any markup.
3. **Render via html-effectiveness.** Invoke the **html-effectiveness** skill to produce the file. It routes this request to its `references/16-implementation-plan.html` demo and composes the artifact from `styles.css` + `patterns.md`. Output is `<topic-slug>-plan.html` plus a sibling `./styles.css` (ensure the stylesheet exists in the output directory — html-effectiveness copies it from its own folder if missing). Fill with specific, real content — no `Lorem ipsum`, no `<!-- TODO -->`.
4. **Hand off as the approval gate.** Suggest `open <file>` (macOS), name the files/areas the work touches, and ask the user to approve the direction before any code is written.

## Document skeleton

Map the plan onto these sections (this is the shape the `16-implementation-plan.html` demo renders well):

- **Objective & done-criteria** — what we're building and what "done" means. One concrete sentence, not "make it work".
- **Scope & non-goals** — what is in this cut and what is explicitly deferred.
- **Approach & key decisions** — the proposed direction with the load-bearing decisions and their rationale. State settled calls as decisions (html-effectiveness `summary-strip` / a decision callout), not as open questions.
- **Steps** — ordered, each naming real files, symbols, and actions, each leading with what it reuses.
- **File map** — the load-bearing files and what changes in each. Highlight only files worth reading, not an exhaustive list.
- **Risks** — what could go wrong and the mitigation.
- **Verification** — a real end-to-end smoke that matches the user journey (a command, a browser path, an on-disk/db assertion), not just typecheck/unit tests.
- **Open Questions** — see below.

## Open questions

Surface genuinely-unresolved decisions in a single **Open Questions** section at the **bottom** of the document — never a wall of questions mid-narrative, and never the same question twice. Each open question states the alternatives and a **recommended default** (the option you would pick) with one line of rationale. If a decision is already made, state it as settled prose or a decision callout instead of parking it here.

A one-line pointer up top ("a few decisions are still open — see Open Questions") is fine; do not reproduce the question list above the bottom section. If you want the reviewer to answer in-page, render this section as a small form using html-effectiveness's `copy-as-X-button` pattern (see its `19-editor-feature-flags.html` demo) so their choices copy back as pasteable text — optional, only when it helps.

## Self-review before handoff (high-stakes plans only)

For architecture, backend, data-model, migration, or otherwise risky plans, run one cheap adversarial pass after rendering — skip it for small or single-decision plans. Present the plan first, then critique the written plan (do not re-research): look for hard-to-reverse decisions made implicitly or not at all, steps not anchored in real files, a menu of options where the plan should commit to one, and padding. Fix clear-cut gaps yourself; route genuine judgment calls into the Open Questions section. Summarize what the pass changed when you next respond.

## Anti-patterns

- Dumping the plan into chat as markdown prose instead of producing the HTML artifact.
- A wireframe/mockup that mixes a real product screen with repo names, file-contract arrows, or architecture notes — keep product screens pure.
- A wall of open questions in the middle of the document, or the same decision asked twice.
- Revision language that only makes sense against the chat ("unlike the earlier draft", "this revises…") — the plan must stand alone.
- A single-step plan, or padding a thin plan with filler to look substantial.
- Re-declaring html-effectiveness's CSS or hardcoding hex colors — rendering belongs to html-effectiveness; use its tokens.
- A verification section that stops at "typecheck passes" when the change touches UI, files, sync, or multi-step flows.
- Editing source files while the plan is still under review — planning is read-only until approval.
