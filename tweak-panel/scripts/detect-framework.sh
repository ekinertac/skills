#!/bin/bash
# Detects the frontend/backend stack in the current working directory
# and outputs a JSON object describing the framework, panel file path,
# dev server command, and local URL to visit.
set -e

CWD="${1:-.}"

framework="unknown"
panel_path=""
dev_command=""
url="http://localhost:3000/tweak-panel"
lang="js"

# Detect TypeScript
if [ -f "$CWD/tsconfig.json" ]; then
  lang="ts"
fi

# Next.js App Router
if [ -f "$CWD/next.config.js" ] || [ -f "$CWD/next.config.ts" ] || [ -f "$CWD/next.config.mjs" ]; then
  if [ -d "$CWD/app" ]; then
    framework="nextjs-app-router"
    panel_path="app/tweak-panel/page.${lang}x"
    dev_command="npm run dev"
    url="http://localhost:3000/tweak-panel"
  else
    framework="nextjs-pages-router"
    panel_path="pages/tweak-panel.${lang}x"
    dev_command="npm run dev"
    url="http://localhost:3000/tweak-panel"
  fi

# Vite
elif [ -f "$CWD/vite.config.js" ] || [ -f "$CWD/vite.config.ts" ]; then
  framework="vite-react"
  panel_path="src/TweakPanel.${lang}x"
  dev_command="npm run dev"
  url="http://localhost:5173/tweak-panel"

# Create React App
elif [ -f "$CWD/package.json" ] && grep -q '"react-scripts"' "$CWD/package.json" 2>/dev/null; then
  framework="cra"
  panel_path="src/TweakPanel.${lang}x"
  dev_command="npm start"
  url="http://localhost:3000/tweak-panel"

# Vue
elif [ -f "$CWD/vite.config.js" ] && grep -q 'vue' "$CWD/package.json" 2>/dev/null; then
  framework="vue"
  panel_path="src/views/TweakPanel.vue"
  dev_command="npm run dev"
  url="http://localhost:5173/tweak-panel"

# Django
elif [ -f "$CWD/manage.py" ]; then
  framework="django"
  panel_path="templates/tweak_panel.html"
  dev_command="python manage.py runserver"
  url="http://localhost:8000/tweak-panel"

# Plain HTML
elif ls "$CWD"/*.html 1>/dev/null 2>&1; then
  framework="plain-html"
  panel_path="tweak-panel.html"
  dev_command="open tweak-panel.html"
  url="tweak-panel.html"
fi

echo "{\"framework\":\"$framework\",\"panel_path\":\"$panel_path\",\"dev_command\":\"$dev_command\",\"url\":\"$url\",\"lang\":\"$lang\"}" >&1
echo "Detected: $framework → $panel_path" >&2
