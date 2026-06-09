---
description: "Execute warden plans. Thin wrapper over `bash .warden/run.sh` that surfaces missing-init errors clearly and passes args through."
allowed-tools: Bash
argument-hint: "[plan-id...] [--strict] [--destructive]"
---

Execute one or more warden plans.

## Parse the input

`$ARGUMENTS` is passed through to the runner unchanged. Supported forms:
- (empty): run every plan in phase order
- `<plan-id>` (one or many): run only those plans by basename match
- `phase:<phase-name>`: run all plans in one phase
- `--strict`: abort the suite on the first failing plan
- `--destructive` / `--yes` / `--force`: skip the destructive countdown
- Any combination

## Precondition: `.warden/` must exist

```bash
if [ ! -f .warden/run.sh ]; then
  echo "warden is not initialized in this project."
  echo "Run /warden:design to bootstrap .warden/ from the plugin templates."
  exit 1
fi
```

If the runner is missing, do not try to recover or fall back to copying templates. Surface the missing init to the user and stop.

## Execute

```bash
bash .warden/run.sh $ARGUMENTS
```

Forward the runner's stdout and stderr unchanged. Capture the exit code.

## Report the outcome

The runner writes its own summary banner. Do not duplicate it. After the runner exits:

- If exit 0: confirm green and point at the run summary (`.warden/runs/<id>.md`).
- If exit 1: state the suite failed; list the failing plans by reading the runner output. Suggest `/warden:triage` to classify the failures and write remediation files.
- If exit 2: a destructive suite refused to run non-interactively. Tell the user to re-run with `--destructive` if they meant it.

Do not analyse failures here; that is `/warden:triage`'s job. The contract for this command is "execute and surface."
