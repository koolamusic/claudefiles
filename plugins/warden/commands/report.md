---
description: "Produce a stakeholder-facing summary of a warden run. Reads the per-run summary plus the JSONL audit trail for trend context. WhatsApp-casual tone, leads with shipped vs regressed."
allowed-tools: Bash, Read, Write
argument-hint: "[run-id]"
---

Write a stakeholder summary for a warden run. Tone is WhatsApp-casual: short, plain, lead with user-impact. No changelog dump. No filler. Own any regressions plainly.

## Parse the input

`$ARGUMENTS`:
- Empty: most recent run.
- `<run-id>`: specific run.

## Read the run

```bash
if [ -n "$ARGUMENTS" ]; then
  RUN_ID="$ARGUMENTS"
else
  RUN_ID=$(ls -1 .warden/runs/*.md 2>/dev/null | sed -E 's|.*/||; s|\.md$||' | sort -r | head -1)
fi
```

Read `.warden/runs/${RUN_ID}.md` for the per-plan results.

## Pull trend context from JSONL

If `.warden/runs/asserts.jsonl` exists, derive:

- **Regressions in this run**: assertions that failed here but passed in the prior run:
  ```bash
  PREV_RUN=$(jq -r ".run" .warden/runs/asserts.jsonl | sort -u | grep -v "$RUN_ID" | tail -1)
  jq -c "select(.run == \"$RUN_ID\" and .status == \"fail\") | .name" .warden/runs/asserts.jsonl > /tmp/now-fail
  jq -c "select(.run == \"$PREV_RUN\" and .status == \"pass\") | .name" .warden/runs/asserts.jsonl > /tmp/prev-pass
  grep -Fxf /tmp/prev-pass /tmp/now-fail   # regressions
  ```

- **Newly green**: assertions that failed in the prior run and pass now.

- **Streaks**: how many consecutive runs the suite has been green or red overall.

If only one run exists, skip trends and report only this run.

## Pull observations

If `.warden/runs/observations.jsonl` exists, mention any standout measurement that changed materially from the prior run (e.g. boot time tripled). Only include if non-trivial.

## Write the report

Path: `.warden/runs/${RUN_ID}-report.md`.

Structure (use only the sections that have content; do not pad):

```markdown
# Run report: ${RUN_ID}

**Status**: green | partial (N failures) | red (M failures)

## What shipped
- One-line takeaways of what's working now that wasn't, if any.

## What regressed
- For each regression: which area, what broke, the assertion id and a half-sentence on impact.
- If zero regressions: skip this section entirely.

## What's still red
- Open failures grouped by phase, one line each.
- Link to .warden/remediation/<file>.md if triage has produced one.

## Trend
- Streak ("green for 4 runs" / "first red after 6 green").
- Any observation worth flagging (boot times, queue depth).
- Skip if there's no signal.

## Next
- One sentence on the recommended next action.
```

## Tone rules

- Lead with impact, not internals. Stakeholders care about "publishing public wikis now works on Railway", not "core/src/routes/wikis.ts line 686 was patched".
- Own the failures plainly. Don't bury or hedge. "Search results stopped loading sometime today. Looks like an API shape change; fix is small."
- No "I am happy to report" / "I'm pleased to share". No emojis unless the user has asked for them previously.
- Code references go in remediation files, not the report.

## Report back

After writing, tell the user:
- Path to the report
- Headline status
- One sentence on the most important thing in it
