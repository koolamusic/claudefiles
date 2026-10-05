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
sudo_ok=1
sudo -n true >/dev/null 2>&1 || sudo_ok=0

apt_get() {   # apt_get <package>  installs one package, or says how to do it by hand
  if [ "$sudo_ok" = 0 ]; then
    echo "$1: sudo needs a password. Run by hand:"
    echo "  $apt install -y $1"
    return 1
  fi
  if [ "$apt_updated" = 0 ]; then $apt update -qq >/dev/null 2>&1 || true; apt_updated=1; fi
  local err
  if err=$($apt install -y -qq "$1" 2>&1 >/dev/null); then
    echo "$1: installed"
  else
    echo "$1: apt-get install failed; last lines of its output:"
    printf '%s\n' "$err" | tail -n 5 | sed 's/^/  /'
    return 1
  fi
}

apt_install() {   # apt_install <package> <command to test for>
  if command -v "$2" >/dev/null 2>&1; then echo "$1: present"; return 0; fi
  apt_get "$1"
}

apt_pkg() {   # apt_pkg <package>  (library packages with no command to test for)
  if dpkg -s "$1" >/dev/null 2>&1; then echo "$1: present"; return 0; fi
  apt_get "$1"
}

echo "== system packages"
[ "$sudo_ok" = 1 ] || echo "sudo -n failed; apt steps are printed, not run"
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
uv sync --locked --project "$here" --python 3.12 "${extras[@]}" && echo "uv sync: ok" || { echo "uv sync: failed (a stale uv.lock fails here; run uv lock in scripts/ and commit it)"; exit 1; }
echo

echo "== kokoro model files -> $model_dir"
mkdir -p "$model_dir"
# sha256 values are the asset digests GitHub publishes for release model-files-v1.1
fetch() {   # fetch <file> <sha256>
  local f="$model_dir/$1"
  if [ -f "$f" ]; then
    if [ "$(sha256sum "$f" | cut -d' ' -f1)" = "$2" ]; then echo "$1: present, sha256 ok"; return 0; fi
    echo "$1: present but sha256 differs from the release; re-downloading"
  else
    echo "$1: downloading"
  fi
  if curl -L --fail --progress-bar -o "$f.part" "$release/$1" \
     && [ "$(sha256sum "$f.part" | cut -d' ' -f1)" = "$2" ]; then
    mv "$f.part" "$f"; echo "$1: ok, sha256 matches the release"
  else
    rm -f "$f.part"; echo "$1: download failed or sha256 mismatch; re-run setup"; return 1
  fi
}
fetch kokoro-v1.0.onnx beb0d1848dee9a49da392cc3df26958d46cfa35d321edf434f52949153f0df3a
fetch voices-v1.0.bin bca610b8308e8d99f32e6fe4197e7ec01679264efed0cac9140fe9c29f1fbf7d
echo

echo "== doctor, after"
bash "$here/doctor.sh"
