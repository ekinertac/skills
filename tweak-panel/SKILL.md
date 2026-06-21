---
name: tweak-panel
description: 'Skip the "a bit more / a bit less" loop — build a floating draggable control panel inside your running app so you can tune parameters yourself, then paste the values back to apply them. For non-browser apps (TUI, CLI, backend, API), writes a tweak-panel.json file instead. Use when tweaking visual styles, animation timing, numeric thresholds, or any set of config values interactively. Trigger phrases: "tweak panel", "control panel", "let me tune this myself", "build a panel for this".'
---

# Tweak Panel

Scaffolds a control panel so you can tune parameters yourself rather than iterating verbally. For browser apps, it's a floating draggable overlay inside your running app. For everything else, it's a `tweak-panel.json` file you edit directly in your editor.

## How It Works

1. Inspect the project (package.json, config files, directory structure) to identify the stack
2. Extract every tweakable param from the target component/file with its current value and sensible min/max
3. **Browser app** → scaffold a floating panel component at the right path for the detected stack
4. **Non-browser app** → write `tweak-panel.json` at the project root
5. Tell the user what to do (visit URL or open the JSON file)
6. Wait for the user to paste back values
7. Apply all values to the source files in one edit pass and delete the panel file

## Path 1 — Browser Apps (floating panel)

**Detected by:** presence of `next.config.*`, `vite.config.*`, `react-scripts`, `vue.config.*`, or HTML entry points.

| Stack | Panel file |
|---|---|
| Next.js App Router | `app/tweak-panel/page.tsx` |
| Next.js Pages Router | `pages/tweak-panel.tsx` |
| Vite / CRA / plain React | `src/TweakPanel.tsx` + route |
| Vue | `src/views/TweakPanel.vue` + route |
| Django / Jinja templates | `templates/tweak_panel.html` + temp URL |
| Plain HTML | `tweak-panel.html` at project root |

**Panel UI requirements:**
- **Floating draggable overlay** — `position: fixed`, high `z-index`, real component fully visible underneath
- **Drag handle** — grip bar at top; vanilla JS mousedown/mousemove/mouseup — works in every stack
- **Default position** — bottom-right corner with comfortable margin
- **Collapsible** — `▾` / `▸` toggle shrinks to title bar only so you can inspect what's behind it
- Width ~300px, max-height 80vh with internal scroll
- Numbers → sliders with live value shown inline; colors → color pickers; booleans → toggles; enums → selects
- **"Copy values" button** — writes JSON to clipboard AND shows it in a `<pre>` for manual copy
- Dark semi-transparent background `rgba(15,15,15,0.92)`, subtle border, rounded corners
- Every param change reflects instantly — no save button

**Tell the user:**
```
Tweak panel is ready at `{file_path}`.
Visit {url} (run `{dev_command}` first if the server isn't up).
Tune the values, click "Copy values", and paste the JSON back here — I'll apply it.
```

## Path 2 — Non-Browser Apps (JSON config file)

**Use this path for:** TUI apps (Textual, Rich, Ink, blessed, tview), CLI tools, backend services, APIs, daemons, scripts — anything without a browser UI.

Write `tweak-panel.json` at the project root with every tweakable param and its current value:

```json
{
  "_instructions": "Edit the values below, save the file, then paste the contents back to the agent.",
  "animation_speed_ms": 120,
  "max_retries": 3,
  "threshold": 0.75,
  "primary_color": "#3b82f6",
  "show_borders": true,
  "log_level": "info"
}
```

Include a `_meta` block with hints so the user knows what each param controls and what range is reasonable:

```json
{
  "_instructions": "Edit values, save, paste back to agent to apply.",
  "_meta": {
    "animation_speed_ms": {"min": 50, "max": 1000, "hint": "lower = faster"},
    "threshold": {"min": 0.0, "max": 1.0, "hint": "confidence cutoff"},
    "log_level": {"options": ["debug", "info", "warning", "error"]}
  },
  "animation_speed_ms": 120,
  "threshold": 0.75,
  "log_level": "info"
}
```

**Tell the user:**
```
tweak-panel.json is ready at the project root.
Open it in your editor, adjust the values, save, then paste the contents back here — I'll apply them.
```

## Cleanup

Both paths are ephemeral. After the user pastes values back:
- Delete `tweak-panel.json` or the panel component file
- Remove any temporary route added to a router file
- Do not commit either file

## Troubleshooting

**Panel file causes a type error** — add `// @ts-nocheck` at the top; it's ephemeral.

**Component doesn't update on slider change** — make sure state is passed as props, not read from a module-level constant.

**App Router panel not found** — confirm `app/tweak-panel/page.tsx` has `"use client"` as the first line.

**Drag doesn't work in Safari** — add `user-select: none` to the drag handle element.
