#!/usr/bin/env bash
set -euo pipefail

if command -v godot4 >/dev/null 2>&1; then
  GODOT_BIN=godot4
elif command -v godot >/dev/null 2>&1; then
  GODOT_BIN=godot
else
  echo "No se encontró Godot 4.3+ (godot o godot4)." >&2
  exit 1
fi

"$GODOT_BIN" --headless --path . --editor --quit
"$GODOT_BIN" --headless --path . --export-release Web "./Miliki y el Pepino.html"
echo "Exportación web lista: Miliki y el Pepino.html"
