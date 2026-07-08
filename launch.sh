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

# Optional AI story brain: pull DEEPSEEK_KEY from AZOTH .env without printing it
AZOTH_ENV="${AZOTH_ENV:-$ROOT/../../.env}"
if [ ! -f "$AZOTH_ENV" ]; then
  AZOTH_ENV="/home/guestpc/AZOTH/.env"
fi
if [ -f "$AZOTH_ENV" ] && [ -z "${DEEPSEEK_KEY:-}" ]; then
  # shellcheck disable=SC1090
  set -a
  # only export the key line safely
  _k="$(grep -E '^DEEPSEEK_KEY=' "$AZOTH_ENV" | head -1 | cut -d= -f2- | tr -d '"' | tr -d "'")"
  if [ -n "$_k" ]; then
    export DEEPSEEK_KEY="$_k"
    echo "⟡ AI story brain: DEEPSEEK_KEY loaded from env file"
  fi
  set +a
fi
if [ -n "${DEEPSEEK_KEY:-}" ]; then
  echo "⟡ AI: on (DeepSeek) — progressive story + help answers"
else
  echo "⟡ AI: offline — School texts only (set DEEPSEEK_KEY to enable)"
fi

echo "⟡ THE LONG LIGHT — School World (Godot 4.3)"
echo "   $GODOT --path $ROOT"
exec "$GODOT" --path "$ROOT" "$@"
