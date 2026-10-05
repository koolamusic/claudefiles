#!/usr/bin/env python3
"""Lint text against Simplified Technical English rules and print JSON findings.

Thin wrapper around the open-source `ste100-checker`, run through uvx.

Usage: ste_check.py FILE   or   cat text.txt | ste_check.py

Needs uv and Python 3.11+. The first run downloads the checker and the spaCy
model en_core_web_sm (wheel 3.8.0, which assumes the checker pins spaCy 3.8;
set STE_SPACY_MODEL to another wheel URL or spec if that changes).
"""

import os
import shutil
import subprocess
import sys
import tempfile

HINT = (
    "ste_check.py: needs uv on PATH (https://docs.astral.sh/uv/) and Python 3.11+; "
    "the first run downloads ste100-checker and the spaCy model en_core_web_sm."
)
MODEL = os.environ.get(
    "STE_SPACY_MODEL",
    "en_core_web_sm@https://github.com/explosion/spacy-models/releases/download/"
    "en_core_web_sm-3.8.0/en_core_web_sm-3.8.0-py3-none-any.whl",
)


def main(argv):
    if argv and argv[0] in ("-h", "--help"):
        print(__doc__.strip())
        return 0
    if shutil.which("uvx") is None:
        print(HINT, file=sys.stderr)
        return 2
    path = argv[0] if argv and argv[0] != "-" else None
    tmp = None
    if path is None:
        tmp = tempfile.NamedTemporaryFile("w", suffix=".txt", delete=False, encoding="utf-8")
        tmp.write(sys.stdin.read())
        tmp.close()
        path = tmp.name
    cmd = ["uvx", "--from", "ste100-checker", "--with", MODEL, "ste100", path, "--format", "json"]
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True)
    finally:
        if tmp is not None:
            os.unlink(tmp.name)
    if proc.stdout.strip():
        sys.stdout.write(proc.stdout)
    else:
        sys.stderr.write(proc.stderr)
        print(HINT, file=sys.stderr)
    return proc.returncode


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
