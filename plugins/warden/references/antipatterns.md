# Antipatterns

Things to avoid. Each entry includes why and what to do instead.

## Mocked databases or services

Wrong:

```bash
# A plan that mocks pg responses with a script
echo '{"rows": 5}' | warden_pass mocked
```

The point of UAT is to catch the integration. Mocks pass when prod
breaks. Robin learned this when a mocked auth flow shipped and the
real cookie path was broken.

Right: hit the real stack. If running against prod is risky, run
against a local stack with the same code.

## Hardcoded URLs

Wrong:

```bash
curl http://localhost:3000/health
```

Different machines, sandbox vs personal vs CI, will use different ports
and hosts. Robin's Railway deploy uses public hostnames that the local
dev env does not.

Right: source `warden_load_env` and use config vars.

```bash
source "$WARDEN_LIB/env.sh"
warden_load_env
curl "$SERVER_URL/health"
```

Default `$SERVER_URL` in `warden.config.sh`; override per environment.

## Plans without prerequisites declared

Wrong: a plan that just starts asserting and crashes the runner if
Postgres is not running.

Right: prerequisites listed in the plan markdown, checked at the top of
the bash block using `warden_wait_*` helpers. Failed prerequisites
should `warden_fail prereq-name` and `exit 0` so the runner records
the failure and moves on.

## Missing the WARDEN_RESULT contract

Wrong: a plan that runs commands and returns exit 0 with no
`warden_pass` / `warden_fail` calls.

```bash
curl -sf "$SERVER_URL/health" >/dev/null
# Plan ends with $? == 0; the runner counts 0 passed, 0 failed
```

The runner counts `WARDEN_RESULT` lines, not exit codes. A plan that
runs to completion with no assertions is silent green. Worse than red.

Right: every check produces a `warden_pass` or `warden_fail` line.

```bash
if curl -sf "$SERVER_URL/health" >/dev/null; then
  warden_pass health
else
  warden_fail health "GET /health failed"
fi
```

## Exiting early on first failure

Wrong:

```bash
warden_pass step-1
[[ "$x" -eq 1 ]] || exit 1   # script ends here
warden_pass step-2
warden_pass step-3
```

The remaining assertions never run, so the runner sees only the failure
that triggered the exit. Other broken things stay hidden.

Right: keep running. Use `warden_fail` for the broken step; the runner
totals everything at the end.

```bash
warden_pass step-1
if [[ "$x" -eq 1 ]]; then
  warden_pass step-x-shape
else
  warden_fail step-x-shape "got $x"
fi
warden_pass step-2
warden_pass step-3
```

Exception: when a prerequisite fails so badly that subsequent assertions
would be meaningless. Then `warden_fail prereq` then `exit 0` (exit zero
keeps the runner from misreporting the bash exit as a plan crash).

## One mega-block when you want narrative

Wrong: 200 lines in a single ```bash block, no narrative structure.

Right: split into multiple bash blocks separated by markdown headings.
The runner concatenates them; the file remains readable. See the
"Multi-block scripts" section in `references/patterns.md`.

## Plans that depend on each other implicitly

Wrong: plan 09 reads a user ID that plan 02 wrote into `/tmp/user-id`.
Anyone running plan 09 in isolation has no way to know about the
dependency.

Right: declare data flow in `SEQUENCE.md`. If plan 09 depends on plan 02,
either run them together via `bash .warden/run.sh phase:auth`, or have
plan 09 do its own setup at the top.

## Decorative dividers in the summary line

Wrong:

```bash
echo "============================================"
echo "  Plan summary: $PASS passed, $FAIL failed"
echo "============================================"
```

Warden does not care; it counts `WARDEN_RESULT` lines, not summary
parsing. But the older Robin runner did parse summaries, and decorative
borders broke it. Avoid leaving brittle artifacts behind for the next
contributor.

Right: let the runner emit its own summary at the bottom. If you want
an in-plan summary for readability, call `warden_summary` from
`assert.sh`.
