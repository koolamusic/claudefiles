#!/usr/bin/env bash
# Installs what the video rung needs on this machine. The only script in this
# skill that installs anything. Safe to re-run; each step skips what is present.
#   bash setup.sh [--latex]      --latex also installs texlive-latex-base for MathTex
set -uo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
model_dir="${KOKORO_MODEL_DIR:-$HOME/.cache/explainer-formats/kokoro}"
release="https://github.com/thewh1teagle/kokoro-onnx/releases/download/model-files-v1.1"
raydr_env="${RAYDR_ENV_FILE:-$HOME/.config/raydr/env}"
latex=0
# needrestart's post-install hook opens a whiptail dialog and waits for a TTY;
# these settings keep every apt call non-interactive.
apt="sudo -n env DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a NEEDRESTART_SUSPEND=1 apt-get -o Dpkg::Options::=--force-confold"
for a in "$@"; do [ "$a" = "--latex" ] && latex=1; done

echo "== doctor, before"
bash "$here/doctor.sh"
echo

apt_updated=0
apt_install() {   # apt_install <package> <command to test for>
  if command -v "$2" >/dev/null 2>&1; then
    echo "$1: present"; return 0
  fi
  if [ "$apt_updated" = 0 ]; then $apt update -qq >/dev/null 2>&1 || true; apt_updated=1; fi
  if $apt install -y -qq "$1" >/dev/null 2>&1; then
    echo "$1: installed"
  else
    echo "$1: needs a password. Run by hand:  sudo apt-get install -y $1"
  fi
}

apt_pkg() {   # apt_pkg <package>  (library packages with no command to test for)
  if dpkg -s "$1" >/dev/null 2>&1; then echo "$1: present"; return 0; fi
  if [ "$apt_updated" = 0 ]; then $apt update -qq >/dev/null 2>&1 || true; apt_updated=1; fi
  if $apt install -y -qq "$1" >/dev/null 2>&1; then echo "$1: installed"
  else echo "$1: needs a password. Run by hand:  sudo apt-get install -y $1"; fi
}

echo "== system packages"
apt_install ffmpeg ffmpeg
apt_install espeak-ng espeak-ng
# manim's pycairo and manimpango have no Linux wheels and build against these
for p in pkg-config libcairo2-dev libpango1.0-dev; do apt_pkg "$p"; done
if [ "$latex" = 1 ]; then apt_install texlive-latex-base latex; else echo "latex: skipped (pass --latex to install texlive-latex-base)"; fi
echo

echo "== python environment (uv, Python 3.12)"
if ! command -v uv >/dev/null 2>&1; then
  echo "uv: missing. Install it first: https://docs.astral.sh/uv/   then re-run this script."; exit 1
fi
extras=()
if [ -n "${ELEVENLABS_API_KEY:-}" ] || grep -qE '^(export )?ELEVENLABS_API_KEY=' "$raydr_env" 2>/dev/null; then
  extras=(--extra elevenlabs); echo "ELEVENLABS_API_KEY is named, so the elevenlabs extra is included"
fi
uv sync --project "$here" --python 3.12 "${extras[@]}" && echo "uv sync: ok" || { echo "uv sync: failed"; exit 1; }
echo

echo "== kokoro model files -> $model_dir"
mkdir -p "$model_dir"
fetch() {   # fetch <file> <minimum bytes>
  local f="$model_dir/$1"
  if [ -f "$f" ] && [ "$(stat -c %s "$f")" -ge "$2" ]; then echo "$1: present"; return 0; fi
  echo "$1: downloading"
  if curl -L --fail --progress-bar -o "$f.part" "$release/$1" && [ "$(stat -c %s "$f.part")" -ge "$2" ]; then
    mv "$f.part" "$f"; echo "$1: ok, sha256 $(sha256sum "$f" | cut -c1-16)..."
  else
    rm -f "$f.part"; echo "$1: download failed or file too small; re-run setup"; return 1
  fi
}
fetch kokoro-v1.0.onnx 300000000
fetch voices-v1.0.bin 25000000
echo

echo "== doctor, after"
bash "$here/doctor.sh"
