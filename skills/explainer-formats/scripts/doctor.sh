#!/usr/bin/env bash
# Read-only check of what the explainer-formats rungs need on this machine.
# Prints a table. Installs nothing; writes only machine.toml (gitignored) in the skill root.
set -u

here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/.." && pwd)"
out="$root/machine.toml"
venv="$here/.venv"
# raydr is a personal voice tool; its env file is only grepped for the key NAME, never read for a value.
raydr_env="${RAYDR_ENV_FILE:-$HOME/.config/raydr/env}"
model_dir="${KOKORO_MODEL_DIR:-$HOME/.cache/explainer-formats/kokoro}"

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

for tool in ffmpeg espeak-ng latex; do
  if command -v "$tool" >/dev/null 2>&1; then
    add "$tool" present "$(command -v "$tool")"
  else
    add "$tool" missing "-"
  fi
done

# The diagram rung: Node 20+, a Chrome-family browser for PNG/GIF/MP4 export, and the engine's own doctor.
if command -v node >/dev/null 2>&1; then
  node_major="$(node -p 'process.versions.node.split(".")[0]')"
  if [ "$node_major" -ge 20 ]; then add node present "$(node --version)"; else add node missing "$(node --version) is older than 20"; fi
else
  add node missing "-"
fi
chrome_bin="$(command -v google-chrome chromium chromium-browser 2>/dev/null | head -1)"
pw_chrome="$(ls -d "$HOME"/.cache/ms-playwright/chromium-*/ 2>/dev/null | sort -V | tail -1)"
if [ -n "${SEECODE_CHROME:-}" ]; then
  add chrome present "SEECODE_CHROME=$SEECODE_CHROME"
elif [ -n "$chrome_bin" ]; then
  add chrome present "$chrome_bin"
elif [ -n "$pw_chrome" ]; then
  add chrome present "Playwright ${pw_chrome%/}; diagram.sh sets SEECODE_CHROME=$here/chromium.sh"
else
  add chrome missing "install Chrome or Chromium, or set SEECODE_CHROME"
fi
if command -v node >/dev/null 2>&1 && [ -f "$here/visualizer/scripts/seecode.mjs" ]; then
  vis="$(bash "$here/diagram.sh" doctor 2>/dev/null)"
  vis_ok="$(printf '%s' "$vis" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{try{const j=JSON.parse(s);console.log((j.ok?"present":"partial")+"|"+Object.entries(j.checks).map(([k,v])=>k+": "+v).join("; "))}catch{console.log("missing|no doctor output")}})')"
  add visualizer "${vis_ok%%|*}" "${vis_ok#*|}"
else
  add visualizer missing "needs node and scripts/visualizer"
fi
if [ -x "$venv/bin/manim" ]; then add manim present "scripts/.venv"; else add manim missing "bash scripts/setup.sh"; fi

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
if [ -s "$model_dir/kokoro-v1.0.onnx" ] && [ -s "$model_dir/voices-v1.0.bin" ]; then add kokoro-models present "$model_dir"; else add kokoro-models missing "bash scripts/setup.sh"; fi

if [ -n "${ELEVENLABS_API_KEY:-}" ]; then
  add ELEVENLABS_API_KEY present "set in environment"
elif grep -qE '^(export )?ELEVENLABS_API_KEY=' "$raydr_env" 2>/dev/null; then
  add ELEVENLABS_API_KEY present "named in $raydr_env"
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
