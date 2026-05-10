<!--
File: html-effectiveness/patterns.md
Role: HTML markup snippets for the 11 recurring building blocks across the
      reference demos. CSS for these classes lives in styles.css; do not
      redeclare it here.
Read alongside: SKILL.md (router), styles.css (style source of truth).
-->

# patterns.md

Eleven reusable HTML building blocks. Each pattern: **Use when**, **Markup**,
optional **Notes**. All classes referenced here are defined in `styles.css`.

---

## 1. prompt-box

**Use when:** showing the prompt that produced this artifact at the top of a page.

```html
<div class="prompt-box">
  <span class="label">Prompt</span>
  Compare three approaches to implementing comment threads on task cards…
</div>
```

---

## 2. eyebrow-header

**Use when:** page-level header — small mono label above the serif h1.

```html
<header>
  <div class="eyebrow">Companion to the blog post</div>
  <h1>The unreasonable <em>effectiveness</em> of HTML</h1>
  <p class="sec-intro">One-paragraph summary of what this artifact is.</p>
</header>
```

**Notes:** `<em>` inside `h1` is convention for an italic accent word; pair it with `h1 em { font-style: italic; color: var(--clay); }` only if the artifact wants the accent (the rule is local, not in styles.css).

---

## 3. sec-head

**Use when:** numbered section header inside a long document (specs, plans, reports).

```html
<section>
  <div class="sec-head">
    <span class="num">01</span>
    <h2>Exploration &amp; Planning</h2>
  </div>
  <p class="sec-intro">One or two sentences setting up what this section is for.</p>
  <!-- section content -->
</section>
```

**Notes:** for a tight bullet list of "this week's wins" / "key takeaways" inside a section, use `<ul class="highlights"><li>…</li></ul>` — gives clay-square bullets and tighter spacing than the default. Defined in styles.css.

---

## 4. card-grid

**Use when:** showing a set of comparable items (links, options, designs, demos).

```html
<div class="card-grid">
  <a class="card" href="#">
    <div class="thumb"><!-- inline SVG illustration --></div>
    <div class="body">
      <div class="title">Card title</div>
      <div class="desc">One-line description of what this card represents.</div>
    </div>
  </a>
  <!-- repeat -->
</div>
```

---

## 5. summary-strip

**Use when:** 4 KPIs / metrics at the top of a status report or implementation plan.

```html
<div class="summary-band">
  <div class="stat-card">
    <div class="stat-label">Shipped</div>
    <div class="stat-value">7</div>
  </div>
  <div class="stat-card">
    <div class="stat-label">In flight</div>
    <div class="stat-value">3</div>
  </div>
  <div class="stat-card">
    <div class="stat-label">Slipped</div>
    <div class="stat-value">1</div>
  </div>
  <div class="stat-card">
    <div class="stat-label">Days to demo</div>
    <div class="stat-value">5</div>
  </div>
</div>
```

**Notes:** for status reports with hero-sized headline numbers, swap `.stat-value` for `.stat-num` (44px serif) and add a `.stat-delta` row underneath (e.g. `<div class="stat-delta up">+2 from last week</div>` — `.up` is olive, `.flat` is grey). For an alert card (e.g. "Slipped"), add the `warn` modifier: `<div class="stat-card warn">…</div>` — adds a clay left border.

---

## 6. swatch

**Use when:** displaying color or design tokens as a visual reference.

```html
<div class="swatch-grid">
  <div class="swatch">
    <div class="chip" style="background: var(--clay)"></div>
    <span class="hex">#D97757</span>
    <span class="token">--clay</span>
  </div>
  <!-- repeat -->
</div>
```

---

## 7. kanban-column

**Use when:** triage / prioritization editors with draggable items across columns (Now / Next / Later / Cut).

```html
<div class="kanban">
  <div class="col">
    <div class="col-head">Now</div>
    <div class="card" draggable="true">PROJ-101 — fix login redirect</div>
    <div class="card" draggable="true">PROJ-104 — empty state copy</div>
  </div>
  <div class="col">
    <div class="col-head">Next</div>
    <!-- … -->
  </div>
  <!-- … -->
</div>
```

**Notes:** `.kanban` and `.col` and `.col-head` are *local* classes — the kanban editor is rare enough that its CSS is not in styles.css. When generating one of these, copy the kanban-specific CSS from `references/18-editor-triage-board.html`. Pair this pattern with the `copy-as-X-button` below.

---

## 8. slider-row

**Use when:** prototype tuning — sliders for animation timings, sizes, easings, etc.

```html
<div class="slider-row">
  <label for="duration">Duration</label>
  <input type="range" id="duration" min="100" max="2000" step="50" value="600">
  <output for="duration"><span id="duration-value">600</span>ms</output>
</div>

<script>
  document.getElementById('duration').addEventListener('input', e => {
    document.getElementById('duration-value').textContent = e.target.value;
  });
</script>
```

**Notes:** local CSS for `.slider-row` (flex row, gap, mono font) goes inside the artifact's `<style>` block — see `references/07-prototype-animation.html` for the canonical layout.

---

## 9. copy-as-X-button

**Use when:** every editor artifact must end with one of these — turns whatever the user did in the UI back into pasteable text. Non-negotiable per the SKILL.md hard rules.

```html
<button id="copy-btn" class="copy-btn">Copy as JSON</button>

<script>
  document.getElementById('copy-btn').addEventListener('click', async () => {
    const payload = JSON.stringify(getCurrentState(), null, 2);
    await navigator.clipboard.writeText(payload);
    const btn = document.getElementById('copy-btn');
    const original = btn.textContent;
    btn.textContent = '✓ Copied';
    setTimeout(() => { btn.textContent = original; }, 1400);
  });

  // getCurrentState() — implement per artifact: read the DOM, return a JS
  // object representing the user's edits.
</script>
```

**Notes:** the button label changes per artifact ("Copy as JSON", "Copy as Markdown", "Copy diff", "Copy parameters"). The "Copied" feedback is the load-bearing UX detail — without it, the user doesn't know the click worked.

---

## 10. inline-svg-figure

**Use when:** illustrations, flowcharts, technical diagrams. Inline SVG is preferred over `<img>` for diagrams so the agent can edit them by hand and the user can copy them out.

```html
<figure class="figure">
  <svg viewBox="0 0 400 200" role="img" aria-label="Token bucket flow">
    <!-- shapes -->
    <rect x="20" y="40" width="100" height="60" rx="8"
          fill="var(--paper)" stroke="var(--g500)" stroke-width="2"/>
    <text x="70" y="76" text-anchor="middle"
          font-family="var(--sans)" font-size="14"
          fill="var(--slate)">Bucket</text>
    <!-- arrows, labels, etc. -->
  </svg>
  <figcaption class="caption">Token bucket — refills at <code>rate</code> per second, capped at <code>burst</code>.</figcaption>
</figure>
```

**Notes:** use `var(--clay)` for the highlighted/hot path; `var(--g500)` for plain strokes; `var(--oat)` for filled accent shapes. See `references/13-flowchart-diagram.html` for canonical conventions. If the figure is a chart inside a card-style container, wrap it in `<div class="chart-panel">` and add `<div class="chart-caption">…</div>` underneath — those classes give it the white-card-on-ivory look used in the status/research demos.

---

## 11. tagged-item-list

**Use when:** "In flight", "Carryover", "Blocked", or any status list where each row has a mono tag badge, a description, and an optional owner name. Common in weekly status reports and incident reports.

```html
<div class="carryover">
  <div class="carry-item">
    <span class="carry-tag">In review</span>
    <div class="carry-body">
      Workspace export to CSV — waiting on pagination review.
      <span class="who">· Sam Reyes</span>
    </div>
  </div>
  <div class="carry-item">
    <span class="carry-tag">Blocked</span>
    <div class="carry-body">
      SSO group mapping — blocked on staging IdP credentials from IT.
      <span class="who">· Priya Anand</span>
    </div>
  </div>
  <div class="carry-item">
    <span class="carry-tag">Slipped</span>
    <div class="carry-body">
      Mobile push reliability dashboard — deprioritised for incident follow-up.
      <span class="who">· Devon Park</span>
    </div>
  </div>
</div>
```

**Notes:** `.carryover`, `.carry-item`, `.carry-tag`, `.carry-body`, and `.who` are *local* classes — their CSS is not in `styles.css`. Copy the following block into the artifact's local `<style>`:

```css
.carryover {
  background: var(--oat);
  border-radius: var(--radius-panel);
  padding: 20px 22px;
}
.carry-item {
  display: flex;
  align-items: baseline;
  gap: 14px;
  padding: 8px 0;
}
.carry-item + .carry-item { border-top: 1px solid rgba(20,20,19,0.08); }
.carry-tag {
  font-family: var(--mono);
  font-size: 11px;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: var(--g700);
  background: var(--ivory);
  border-radius: 4px;
  padding: 3px 7px;
  flex-shrink: 0;
}
.carry-body { font-size: 14px; color: var(--g700); }
.carry-body .who { color: var(--g500); font-size: 12px; }
```

Canonical demo: `references/11-status-report.html`.
