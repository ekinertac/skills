---
name: tweak-panel
description: Skip the "a bit more / a bit less" loop — build a floating draggable control panel inside your running app so you can tune parameters yourself, then paste the values back to apply them. Use when tweaking visual styles, animation timing, numeric thresholds, or any set of config values interactively. Trigger phrases: "tweak panel", "control panel", "let me tune this myself", "build a panel for this".
---

# Tweak Panel

Scaffolds a floating, draggable control panel directly inside your running app. You tune sliders, color pickers, and toggles while seeing your real component react live — then copy the final values back to the agent to apply.

## How It Works

1. Run `detect-framework.sh` to identify the stack and where to put the panel file
2. Extract every tweakable param from the target component: numbers → sliders, colors → color pickers, booleans → toggles, enums → selects
3. Scaffold the panel file in the right location for the detected stack (see below)
4. Tell the user which URL to visit and which dev server command to run if needed
5. Wait for the user to paste back the copied JSON values
6. Apply all values to the source files in one edit pass and delete the panel file

## Usage

```bash
bash /mnt/user-data/uploads/tweak-panel/scripts/detect-framework.sh
```

Run this first. It outputs JSON describing the stack and the suggested panel file path.

**Supported stacks and where the panel is created:**

| Stack | Panel file |
|---|---|
| Next.js App Router | `app/tweak-panel/page.tsx` |
| Next.js Pages Router | `pages/tweak-panel.tsx` |
| Vite / CRA / plain React | `src/TweakPanel.tsx` + route |
| Vue | `src/views/TweakPanel.vue` + route |
| Django / Jinja | `templates/tweak_panel.html` + temp URL |
| Plain HTML | `tweak-panel.html` at project root |

## Panel UI Requirements (all stacks)

- **Floating draggable overlay** — `position: fixed`, high `z-index`, renders on top of the page so the real component is fully visible underneath
- **Drag handle** — grip bar at top; vanilla JS mousedown/mousemove/mouseup drag — works in every stack
- **Default position** — bottom-right corner with comfortable margin
- **Collapsible** — `▾` / `▸` toggle shrinks to just the title bar so you can inspect what's behind it
- **Width ~300px**, max-height 80vh with internal scroll
- Controls show live numeric values inline next to sliders
- **"Copy values" button** — writes JSON to clipboard AND shows it in a `<pre>` inside the panel for manual copy
- Dark semi-transparent background `rgba(15,15,15,0.92)`, subtle border, rounded corners
- Every param change reflects instantly — no save button

## Output

```
✓ Detected: Next.js App Router (TypeScript)
✓ Panel created: app/tweak-panel/page.tsx
✓ Parameters found: 8

→ Visit http://localhost:3000/tweak-panel
→ Tune the values, click "Copy values", paste back here
```

## Present Results to User

After creating the panel file, tell the user:

```
Tweak panel is ready at `{file_path}`.

Visit {url} (run `{dev_command}` first if the server isn't up).

Tune the values, click "Copy values", and paste the JSON back here — I'll apply it to the source.
```

## Troubleshooting

**Panel file causes a type error** — add `// @ts-nocheck` at the top of the file; it's ephemeral.

**Component doesn't update on slider change** — make sure state is passed as props, not read from a module-level constant.

**Can't find the tweak-panel route** — for App Router, confirm `app/tweak-panel/page.tsx` has `"use client"` as the first line.

**Drag doesn't work in Safari** — add `user-select: none` to the drag handle element.

## Cleanup

The panel file is ephemeral. After the user pastes values back:
- Delete the panel file
- Remove any temporary route added to a router file
- Do not commit the panel file (add to `.gitignore` if needed)
