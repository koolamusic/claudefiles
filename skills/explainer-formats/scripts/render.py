#!/usr/bin/env python3
"""Render Manim beats, mux narration, concatenate, and report the file size.

Usage:
    uv run --project scripts python scripts/render.py scenes.py beats/ --out video/ \
        [--quality draft|final] [--only N] [--target-mb 15]

scenes.py holds one Scene class per beat, named Beat01, Beat02, ...; beats/ is
the directory tts.py wrote (beat_NN.wav and durations.json). With --only N
the script renders and muxes that one beat and stops, which is the fix loop.
"""

import argparse
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

CAP_SUPPORTING_FILE = 15 * 1000 * 1000   # artifact supporting file, 15 MB
CAP_ASSET = 20 * 1024 * 1024             # artifact asset, 20 MiB
AUDIO_KBPS = 128


def run(cmd, **kw):
    proc = subprocess.run(cmd, text=True, capture_output=True, **kw)
    if proc.returncode != 0:
        sys.stderr.write(proc.stdout[-3000:] + proc.stderr[-3000:])
        sys.exit(f"failed: {' '.join(str(c) for c in cmd[:3])} ...")
    return proc


def need(tool):
    if shutil.which(tool) is None:
        sys.exit(f"{tool} not found on PATH; run: bash scripts/setup.sh")
    return tool


def probe_seconds(path):
    out = run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", str(path)])
    return float(out.stdout.strip())


def render_beat(scenes, n, quality, out, beats_dir):
    media = out / "media"
    flag = "-ql" if quality == "draft" else "-qh"
    env = dict(os.environ, EXPLAINER_BEATS_DIR=str(beats_dir))
    cmd = [sys.executable, "-m", "manim", "render", flag, "--media_dir", str(media),
           "-o", f"beat_{n:02d}.mp4", str(scenes), f"Beat{n:02d}"]
    print(f"beat {n:02d}: manim {flag} Beat{n:02d}")
    proc = subprocess.run(cmd, text=True, capture_output=True, env=env)
    if proc.returncode != 0:
        sys.stderr.write(proc.stdout[-4000:] + proc.stderr[-4000:])
        sys.exit(f"beat {n:02d}: manim failed; fix Beat{n:02d} in {scenes} and re-run with --only {n}")
    hits = sorted(media.glob(f"videos/**/beat_{n:02d}.mp4"), key=lambda p: p.stat().st_mtime)
    if not hits:
        sys.exit(f"beat {n:02d}: manim produced no beat_{n:02d}.mp4 under {media}")
    return hits[-1]


def mux(video, wav, dest):
    run(["ffmpeg", "-y", "-v", "error", "-i", str(video), "-i", str(wav),
         "-c:v", "copy", "-c:a", "aac", "-b:a", f"{AUDIO_KBPS}k", "-shortest",
         "-movflags", "+faststart", str(dest)])
    return dest


def concat(parts, dest):
    listing = dest.with_suffix(".txt")
    listing.write_text("".join(f"file '{p.resolve()}'\n" for p in parts))
    run(["ffmpeg", "-y", "-v", "error", "-f", "concat", "-safe", "0", "-i", str(listing),
         "-c", "copy", "-movflags", "+faststart", str(dest)])
    return dest


def shrink(src, dest, target_mb):
    seconds = probe_seconds(src)
    total_kbps = target_mb * 8000 * 0.95 / seconds
    video_kbps = max(int(total_kbps - AUDIO_KBPS), 200)
    print(f"re-encoding to fit {target_mb} MB: {video_kbps} kbps video over {seconds:.1f}s")
    run(["ffmpeg", "-y", "-v", "error", "-i", str(src), "-c:v", "libx264", "-preset", "slow",
         "-b:v", f"{video_kbps}k", "-maxrate", f"{video_kbps}k", "-bufsize", f"{2 * video_kbps}k",
         "-c:a", "copy", "-movflags", "+faststart", str(dest)])
    return dest


def report(path):
    size = path.stat().st_size
    mb = size / 1e6
    seconds = probe_seconds(path)
    print(f"{path}: {seconds:.1f}s, {mb:.2f} MB")
    print(f"  under 15 MB supporting-file cap: {'yes' if size < CAP_SUPPORTING_FILE else 'no'}")
    print(f"  under 20 MiB asset cap:          {'yes' if size < CAP_ASSET else 'no'}")
    return size


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("scenes", type=Path)
    ap.add_argument("beats", type=Path, help="directory from tts.py")
    ap.add_argument("--out", type=Path, required=True)
    ap.add_argument("--quality", choices=["draft", "final"], default="draft")
    ap.add_argument("--only", type=int, default=None, help="render one beat and stop")
    ap.add_argument("--target-mb", type=float, default=None, help="re-encode final.mp4 to fit this size")
    args = ap.parse_args()

    need("ffmpeg"), need("ffprobe")
    durations = json.loads((args.beats / "durations.json").read_text())
    numbers = [int(k) for k in durations]
    if args.only is not None:
        if args.only not in numbers:
            sys.exit(f"beat {args.only} is not in durations.json ({sorted(numbers)})")
        numbers = [args.only]
    args.out.mkdir(parents=True, exist_ok=True)

    parts = []
    for n in sorted(numbers):
        wav = args.beats / f"beat_{n:02d}.wav"
        if not wav.is_file():
            sys.exit(f"missing {wav}; run tts.py first")
        video = render_beat(args.scenes, n, args.quality, args.out, args.beats)
        part = mux(video, wav, args.out / f"beat_{n:02d}.mp4")
        vs, as_ = probe_seconds(video), durations[str(n)]
        if vs + 0.25 < as_:
            print(f"  warning: Beat{n:02d} video is {vs:.1f}s but narration is {as_:.1f}s; "
                  f"-shortest will cut the narration. Add self.wait() to the scene.")
        parts.append(part)

    if args.only is not None:
        report(parts[0])
        return
    final = concat(parts, args.out / "final.mp4")
    size = report(final)
    if args.target_mb and size > args.target_mb * 1e6:
        raw = final.rename(args.out / "final_raw.mp4")
        shrink(raw, final, args.target_mb)
        report(final)


if __name__ == "__main__":
    main()
