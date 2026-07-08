#!/usr/bin/env bash
# THE LONG LIGHT — School World (Godot 4.3)
set -e
ROOT="$(cd "$(dirname "$0")" && pwd)"
GODOT="${GODOT:-$ROOT/../tools/godot}"
if [ ! -x "$GODOT" ]; then
  GODOT="$ROOT/../tools/Godot_v4.3-stable_linux.x86_64"
fi
if [ ! -x "$GODOT" ]; then
  echo "Godot not found. Expected: $ROOT/../tools/godot"
  exit 1
fi
echo "⟡ THE LONG LIGHT — School World (Godot 4.3)"
echo "   $GODOT --path $ROOT"
exec "$GODOT" --path "$ROOT" "$@"
