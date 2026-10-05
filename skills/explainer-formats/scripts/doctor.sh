#!/usr/bin/env bash
# Read-only check of what the explainer-formats rungs need on this machine.
# Prints a table and writes machine.toml in the skill root. Installs nothing.
set -u

here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/.." && pwd)"
out="$root/machine.toml"
venv="$here/.venv"

rows=()   # name|status|detail
add() { rows+=("$1|$2|$3"); }

if command -v python3 >/dev/null 2>&1; then
  add python3 present "$(python3 --version 2>&1)"
else
  add python3 missing "-"
fi

if command -v uv >/dev/null 2>&1; then
  add uv present "$(uv --version 2>&1)"
  if uv python list --only-installed 2>/dev/null | grep -q 'cpython-3\.12'; then
    add uv-python-3.12 present "managed by uv"
  else
    add uv-python-3.12 missing "uv python install 3.12"
  fi
else
  add uv missing "https://docs.astral.sh/uv/"
  add uv-python-3.12 missing "needs uv"
fi

for tool in ffmpeg manim espeak-ng; do
  if command -v "$tool" >/dev/null 2>&1; then
    add "$tool" present "$(command -v "$tool")"
  else
    add "$tool" missing "-"
  fi
done

if [ -x "$venv/bin/python" ]; then
  py="$venv/bin/python"; where="scripts/.venv"
else
  py="python3"; where="system python3"
fi
if "$py" -c 'import kokoro_onnx' >/dev/null 2>&1; then
  add kokoro-onnx present "$where"
else
  add kokoro-onnx missing "not importable from $where"
fi

if [ -n "${ELEVENLABS_API_KEY:-}" ]; then
  add ELEVENLABS_API_KEY present "set in environment"
elif grep -qE '^(export )?ELEVENLABS_API_KEY=' "$HOME/.config/raydr/env" 2>/dev/null; then
  add ELEVENLABS_API_KEY present "named in ~/.config/raydr/env"
else
  add ELEVENLABS_API_KEY missing "-"
fi

printf '%-22s %-8s %s\n' ITEM STATUS DETAIL
{
  echo "hostname = \"$(hostname)\""
  echo "date = \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\""
  echo
  echo "[items]"
} > "$out"
for row in "${rows[@]}"; do
  IFS='|' read -r name status detail <<< "$row"
  printf '%-22s %-8s %s\n' "$name" "$status" "$detail"
  printf '"%s" = "%s"\n' "$name" "$status" >> "$out"
done
echo
echo "wrote $out"
