#!/usr/bin/env bash
# name: postflight.sh
# purpose: Gate a finished take before anything leaves the host.
# usage: postflight.sh <take-dir> ['<revoke check command>']
#   The revoke check is required when .take/secrets.env sets DEMO_KEY. It runs with
#   that file sourced and must print the HTTP status of a request made with the
#   demo key, for example:
#     'curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $DEMO_KEY" https://api.example.com/v1/me'
#   Only 401 or 403 counts as revoked.
# checks: demo key revoked; no key material in text artefacts other than the revoked
#   demo key; .take/ is gitignored. Extra regexes go in .take/patterns, one per line.
# exit: 0 when every check passes, 1 otherwise.
set -uo pipefail

take=${1:?usage: postflight.sh <take-dir> ['<revoke check command>']}
check=${2:-}
cd "$take" || exit 1
fail=0
DEMO_KEY=

if [ -f .take/secrets.env ]; then
  # shellcheck source=/dev/null
  . .take/secrets.env
fi

if [ -n "$DEMO_KEY" ]; then
  if [ -z "$check" ]; then
    echo "FAIL  revoke: .take/secrets.env sets DEMO_KEY but no revoke check command was given"
    fail=1
  else
    status=$(eval "$check")
    case "$status" in
      401 | 403) echo "ok    revoke: demo key rejected with $status" ;;
      *) echo "FAIL  revoke: demo key still answers with '$status'; revoke it before publishing"; fail=1 ;;
    esac
  fi
else
  echo "ok    revoke: no DEMO_KEY in .take/secrets.env, nothing to revoke"
fi

patterns=$(mktemp)
trap 'rm -f "$patterns"' EXIT
cat > "$patterns" <<'EOF'
sk-[A-Za-z0-9_-]{20,}
(sk|pk|rk)_(live|test)_[A-Za-z0-9]{16,}
gh[pousr]_[A-Za-z0-9]{36,}
xox[abprs]-[A-Za-z0-9-]{10,}
AKIA[0-9A-Z]{16}
AIza[0-9A-Za-z_-]{35}
-----BEGIN [A-Z ]*PRIVATE KEY-----
bearer [A-Za-z0-9._~+/=-]{20,}
eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}
(api[_-]?key|secret|token|password)["' ]*[:=] *["']?[A-Za-z0-9._~+/-]{16,}
EOF
[ -f .take/patterns ] && cat .take/patterns >> "$patterns"

# -I skips binaries (mp4, webm, png, gif); stills are checked by eye below.
hits=$(grep -rIoniE --exclude-dir=.take --exclude-dir=node_modules --exclude-dir=.git -f "$patterns" . || true)
if [ -n "$DEMO_KEY" ]; then
  allowed=$(grep -rIlF --exclude-dir=.take --exclude-dir=node_modules --exclude-dir=.git -- "$DEMO_KEY" . || true)
  [ -n "$hits" ] && hits=$(printf '%s\n' "$hits" | grep -vF -- "$DEMO_KEY" || true)
  [ -n "$allowed" ] && echo "note  demo key appears in: $(printf "%s" "$allowed" | tr "\n" " ")— allowed once the key is revoked."
fi
if [ -n "$hits" ]; then
  echo "FAIL  grep: key material in text artefacts:"
  printf '%s\n' "$hits" | cut -c1-160 | sed 's/^/        /'
  fail=1
else
  echo "ok    grep: no key material in text artefacts"
fi

if git rev-parse --is-inside-work-tree >/dev/null 2>&1 && [ -d .take ]; then
  if git check-ignore -q .take; then
    echo "ok    git: .take/ is ignored"
  else
    echo "FAIL  git: .take/ is not gitignored; add it before committing the shot list"
    fail=1
  fi
fi

stills=$(find . -maxdepth 1 -name "[0-9][0-9]-*.png" | wc -l)
echo "todo  look at each of the $stills stills and the video: a key on screen other than the revoked demo key fails the take"

[ "$fail" -eq 0 ] && echo "PASS  take may be published" || echo "BLOCKED  fix the failures above, then run postflight again"
exit "$fail"
