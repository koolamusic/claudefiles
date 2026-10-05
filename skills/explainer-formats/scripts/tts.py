#!/usr/bin/env python3
"""Narrate a beats script into one WAV per beat (24 kHz mono) plus durations.json.

Usage:
    uv run --project scripts python scripts/tts.py beats.md --out beats/ \
        [--backend kokoro|elevenlabs|espeak] [--voice ID] [--speed 1.0]

The beats script is Markdown: a "## Beat N" heading, then the narration
paragraph. Lines starting with "visual:" describe the scene and are skipped.
"""

import argparse
import json
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

import numpy as np
import soundfile as sf

RATE = 24000
RAYDR_ENV = Path(os.environ.get("RAYDR_ENV_FILE", Path.home() / ".config/raydr/env"))
MODEL_DIR = Path(os.environ.get("KOKORO_MODEL_DIR", Path.home() / ".cache/explainer-formats/kokoro"))


def parse_beats(text):
    beats, current = {}, None
    for line in text.splitlines():
        m = re.match(r"^##\s+Beat\s+(\d+)\s*$", line.strip(), re.I)
        if m:
            current = int(m.group(1))
            beats[current] = []
        elif current is not None and line.strip() and not line.strip().lower().startswith("visual:"):
            beats[current].append(line.strip())
    return {n: " ".join(lines) for n, lines in beats.items() if lines}


def env_value(name):
    """Environment first, then the raydr env file. Returns the value; never prints it."""
    if os.environ.get(name):
        return os.environ[name]
    if RAYDR_ENV.is_file():
        for line in RAYDR_ENV.read_text().splitlines():
            m = re.match(r"^(?:export\s+)?%s=(.*)$" % re.escape(name), line.strip())
            if m:
                return m.group(1).strip().strip("'\"")
    return None


def resample(samples, rate):
    if rate == RATE:
        return samples
    n = int(len(samples) * RATE / rate)
    return np.interp(np.linspace(0, len(samples) - 1, n), np.arange(len(samples)), samples)


def kokoro_backend(voice, speed):
    from kokoro_onnx import Kokoro

    model, voices = MODEL_DIR / "kokoro-v1.0.onnx", MODEL_DIR / "voices-v1.0.bin"
    if not (model.is_file() and voices.is_file()):
        sys.exit(f"kokoro model files missing in {MODEL_DIR}; run: bash scripts/setup.sh")
    engine = Kokoro(str(model), str(voices))

    def speak(text):
        samples, rate = engine.create(text, voice=voice or "af_heart", speed=speed, lang="en-us")
        return resample(np.asarray(samples, dtype=np.float32), rate)

    return speak


def elevenlabs_backend(voice, speed):
    try:
        from elevenlabs.client import ElevenLabs
    except ImportError:
        sys.exit("elevenlabs SDK missing; run: uv sync --project scripts --extra elevenlabs")
    key = env_value("ELEVENLABS_API_KEY")
    if not key:
        sys.exit("ELEVENLABS_API_KEY not set in the environment or the raydr env file")
    voice_id = voice or env_value("ELEVENLABS_VOICE_ID") or "21m00Tcm4TlvDq8ikWAM"
    client = ElevenLabs(api_key=key)   # --speed is ignored here; set speed on the voice

    def speak(text):
        chunks = client.text_to_speech.convert(
            voice_id=voice_id, text=text, model_id="eleven_multilingual_v2", output_format="pcm_24000"
        )
        raw = b"".join(chunks)
        return np.frombuffer(raw, dtype="<i2").astype(np.float32) / 32768.0

    return speak


def espeak_backend(voice, speed):
    def speak(text):
        with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
            path = tmp.name
        cmd = ["espeak-ng", "-v", voice or "en-us", "-s", str(int(175 * speed)), "-w", path, text]
        try:
            subprocess.run(cmd, check=True, capture_output=True)
            samples, rate = sf.read(path, dtype="float32")
        finally:
            os.unlink(path)
        if samples.ndim > 1:
            samples = samples.mean(axis=1)
        return resample(samples, rate)

    return speak


BACKENDS = {"kokoro": kokoro_backend, "elevenlabs": elevenlabs_backend, "espeak": espeak_backend}


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("beats", help="beats script (Markdown)")
    ap.add_argument("--out", required=True, help="output directory")
    ap.add_argument("--backend", choices=BACKENDS, default="kokoro")
    ap.add_argument("--voice", default=None, help="kokoro voice (af_heart), ElevenLabs voice id, or espeak voice")
    ap.add_argument("--speed", type=float, default=1.0)
    ap.add_argument("--only", type=int, default=None, help="narrate a single beat number")
    args = ap.parse_args()

    beats = parse_beats(Path(args.beats).read_text())
    if not beats:
        sys.exit("no '## Beat N' sections with narration found")
    if args.only is not None:
        beats = {args.only: beats[args.only]}
    out = Path(args.out); out.mkdir(parents=True, exist_ok=True)
    speak = BACKENDS[args.backend](args.voice, args.speed)

    durations_path = out / "durations.json"
    durations = json.loads(durations_path.read_text()) if durations_path.is_file() else {}
    for n in sorted(beats):
        try:
            samples = speak(beats[n])
        except Exception as e:   # one line, the error class and status only; never the payload or key
            sys.exit(f"beat {n:02d}: {args.backend} failed: {type(e).__name__} {getattr(e, 'status_code', '')}".rstrip())
        sf.write(out / f"beat_{n:02d}.wav", samples, RATE, subtype="PCM_16")
        durations[str(n)] = round(len(samples) / RATE, 3)
        print(f"beat {n:02d}: {durations[str(n)]:.2f}s  ({len(beats[n].split())} words, {args.backend})")
    durations_path.write_text(json.dumps(durations, indent=2, sort_keys=True) + "\n")
    print(f"wrote {durations_path}")


if __name__ == "__main__":
    main()
