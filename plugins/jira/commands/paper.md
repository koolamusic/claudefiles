---
description: Write an evidence-disciplined engineering paper (innovation/discovery/finding) from a freeform description of what happened. Internally rigorous (evidence inventory, claim-strength discipline, adversarial review), lean single-file HTML house style for output. Publish is opt-in.
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent, AskUserQuestion
argument-hint: <freeform description of what happened> [--category innovation|discovery|finding] [--out <dir>] [--publish <slug>]
---

Turn a real engineering finding, discovery, or innovation into a short, rigorous, single-file HTML paper — evidence-gated internally, magazine-lean on the page. This command runs the house master prompt's discipline (evidence before prose, claim strength matched to evidence strength, stop when the evidence doesn't support the claim) but skips its heavier academic apparatus (no Abstract/Keywords/Related-Work-as-sections, no external literature search) because nothing in this house's paper corpus uses it. If a paper genuinely needs to cite external prior work, the user supplies verified sources — this command does not go looking for them.

## Parse the input

`$ARGUMENTS`:

- **Description** (positional, required unless `--publish` is given): freeform text — what was built, changed, tested, or discovered, and why it mattered. If empty, use `AskUserQuestion` to collect it in one question (what happened / why it mattered / roughly when).
- `--category innovation|discovery|finding` (optional): skip the categorization step if given.
- `--out <dir>` (optional): override the resolved artifacts directory.
- `--publish <slug>`: skip straight to the **Publish gate** (step 8) for an existing `artifacts/drafts/<slug>.html` — no redrafting, no re-review. Use this after hand-editing a draft.

## Resolve the artifacts directory

1. `--out <dir>` wins if given.
2. Else, if `.jira` is a symlink (studio-managed project): `studio_root=$(dirname "$(readlink -f .jira)")`, use `$studio_root/artifacts`.
3. Else: `<repo-root>/artifacts`.
4. Ensure `<artifacts-dir>/drafts/` exists (`mkdir -p`).
5. If `<artifacts-dir>/index.html` doesn't exist, bootstrap it from `${CLAUDE_PLUGIN_ROOT}/templates/paper/index.html` — ask the user for a one-line site title and intro via `AskUserQuestion` if not inferable from the repo name and README.

If `--publish <slug>` was given, skip to step 8 now.

## Steps

1. **Evidence inventory (internal — not a user-facing checkpoint).**

   Read the user's description. Then actively hunt for supporting evidence:
   - `git log`, `git show <sha>`, `git log --grep` for named or implied commits
   - `gh pr list` / `gh pr view` if a PR is referenced and `gh` is available
   - `.jira/sprints/*/RESEARCH.md`, `EXECUTION.md`, `VERIFICATION.md`, `RETRO.md` for anything matching the described work
   - `.warden/logs/`, `.warden/runs/` for measured run output, if present
   - migration files, config diffs, benchmark output the user pasted inline

   Build an internal evidence table (item, source, reliability, limitations) and classify every candidate claim: direct observation / measured result / statistical inference / engineering interpretation / practitioner judgment / hypothesis / speculation / recommendation. Do not show this table to the user unless asked — it's scratch work that feeds the readiness gate and the draft.

2. **Readiness gate.**

   Rate: **Not ready** / **Partially ready** / **Ready to draft**.

   - **Not ready** (no evidence for the primary claim, baseline missing, sources materially conflict, required measurement doesn't exist): stop. Tell the user exactly what's missing. `AskUserQuestion`: (a) supply the missing evidence now, (b) proceed anyway with the affected claims downgraded to hypothesis/speculation and flagged in the draft, (c) abandon.
   - **Partially ready**: proceed, but every under-evidenced claim gets downgraded language and an explicit caveat (see `finding-bottleneck-that-wasnt.html`'s "Honest caveat on the absolute numbers" for the tone to match).
   - **Ready to draft**: proceed.

3. **Category and framing.**

   Propose a category (`innovation` | `discovery` | `finding` — skip if `--category` was passed) and a single neutral research-question framing (not "how did X transform Y" — "how did replacing X with Y affect \<measurable outcome\> under \<observed condition\>"). State the choice; only ask if genuinely ambiguous between two categories.

4. **Draft.**

   Read `${CLAUDE_PLUGIN_ROOT}/templates/paper/PAPER.html` fresh (do not inline its contents from memory). Fill every placeholder:
   - Title: specific, searchable, no promotional language ("revolutionary", "groundbreaking", "novel", "next-generation") unless the evidence justifies it — it almost never does.
   - Why/What/How abstract: one sentence each, every number in it must reappear sourced in §4 or §8.
   - The 8 fixed sections (Background, Problem, Method, Results & Evidence, Verification & Testing, Discussion, Reproducibility, References) — do not add, remove, or rename sections.
   - Any claim without a traceable source becomes an explicit placeholder — `[DATA REQUIRED: ...]` or `[CITATION REQUIRED: ...]` — never invented. List every placeholder in your eventual report.
   - Preserve negative/mixed results — a regression, a rejected hypothesis, or a cost the evidence surfaced does not get dropped for narrative cleanliness.
   - Typography, outside `<pre>`/`<code>`: no em-dash (`—`), no curly/smart quotes, no unicode ellipsis character (`…`). Use a plain hyphen, straight quotes, and `...`. En-dash for numeric ranges (`20:13–20:49`), math/technical symbols (`×`, `→`, `±`, `≈`, `Δ`, etc.), and content inside `<pre>`/`<code>` (diagrams, log output, truncated identifiers) are unaffected — this is about avoiding AI-tell punctuation in prose, not stripping meaningful notation.
   - Time rule: every domain coordinate a reader meets (ledger number, block height, epoch counter, build number) carries its calendar date at first use, every range carries a human span, and every wall-clock figure reads as a felt duration. The date leads, the coordinate stays in support for reproducibility: "from the pool's deployment (March 2025, ledger 56,567,000) to July 24, 2026 - about 14 months of history". Dates come from an authoritative source (git log, log timestamps, a ledger explorer) - never inferred. No source: `[DATA REQUIRED: calendar date for <coordinate>]`.
   - Jargon rule: each project-internal term ("tip", "serving head", medallion layer names, phase names) is either replaced with plain words ("the most recent ledgers", "the live database") or defined once in passing and then used sparingly. Test per occurrence: would a competent engineer who has never seen this codebase follow the sentence cold?

   Save to `<artifacts-dir>/drafts/<slug>.html`, where `<slug>` is `<category>-<kebab-title>` matching the existing naming convention (e.g. `finding-bottleneck-that-wasnt.html`). Prepend the draft-comment header (draft date, proposed category, proposed `index-entry.html` fill-in, sources) and the visible `.draft-banner` div, matching the existing drafts/ convention exactly.

5. **Adversarial review.**

   Spawn `jira-paper-reviewer` with: draft path, the evidence table + claim classifications from step 1, and any raw evidence paths. It returns a YAML verdict (`APPROVED` | `REVISE`) with findings and `required_revisions`.

6. **Stall-aware revision loop (max 2 iterations).**

   - If `verdict: REVISE`: apply the required revisions yourself (you drafted it; the reviewer doesn't edit), then re-spawn `jira-paper-reviewer` for a second pass.
   - Track issue counts across passes. If the second pass's `issue_count` didn't drop, or `escalate: true` — stop. Surface the findings via `AskUserQuestion`: (a) publish with issues noted, (b) I'll hand-edit the draft first, (c) abandon.
   - **At most 2 review passes.**

7. **Confidentiality check before publish.** Grep the draft for anything resembling a credential, DSN, API key, internal hostname, or customer-identifying detail. If found, stop — do not publish; report exactly what and where, and let the user decide whether to redact or abandon.

8. **Publish gate.**

   Report: draft path, category, title, evidence-gap count (remaining `[DATA REQUIRED]`/`[CITATION REQUIRED]` placeholders, each listed), reviewer verdict.

   `AskUserQuestion` — *"Publish this paper now?"*:
   - **A. Publish** — move `drafts/<slug>.html` → `<artifacts-dir>/<slug>.html`; strip the draft-banner div and draft-comment header; insert the `index-entry.html` fragment (filled in) into `index.html` under the matching `<h2>` section (create the section if the index doesn't have it yet).
   - **B. I'll edit the draft first** — leave it in `drafts/`; tell the user to rerun `/jira:paper --publish <slug>` when ready.
   - **C. Keep as draft only** — no further action.

9. **Commit.**

   Draft only:
   ```bash
   git add <artifacts-dir>/drafts/<slug>.html
   git commit -m "paper(<slug>): draft <category> paper on <short-topic>"
   ```

   Published:
   ```bash
   git add <artifacts-dir>/<slug>.html <artifacts-dir>/index.html
   git commit -m "paper(<slug>): publish <category> paper on <short-topic>"
   ```

10. **Final report:** category, title, path, publish status, remaining placeholder count (if kept as draft), next step.

## Hard rules

- **Never invent evidence.** No fabricated measurements, citations, commit SHAs, or outcomes. A gap becomes a placeholder, not a plausible-sounding number.
- **Claim strength must match evidence strength.** No "proved / eliminated / optimal / significant / dramatically / best / revolutionary" without justification from the evidence inventory.
- **Preserve negative and mixed results.** Do not let the adversarial review be the only thing that catches a hidden regression — check for this in the draft yourself, first.
- **No external literature search.** This command is internal-evidence-only by design (see corpus precedent). If a real citation to outside work is needed, the user supplies it verified; do not search for or fabricate one.
- **Stop conditions are not solved with persuasive writing.** No evidence for the primary claim, a missing baseline, conflicting sources, an unclear evaluation method, or a confidentiality risk — surface it via `AskUserQuestion`, don't write around it.
- **Draft-first, publish is opt-in.** Never append to `index.html` or move a file out of `drafts/` without the explicit publish confirmation.
- **Templates live under `${CLAUDE_PLUGIN_ROOT}/templates/paper/`.** Read them fresh every invocation.
- **Does not touch `.jira/STATE.md`.** Papers are not sprint-scoped — this command has no dependency on an active sprint and doesn't update sprint state.
- **Section list is fixed at 8.** Do not add an Abstract-as-a-section, Keywords, Related Work, or Threats-to-Validity as literal sections — that rigor lives in the process (steps 1-2), not the page.
- **Write for a reader who has never seen the codebase.** Calendar time over domain coordinates, no unexplained insider terms. Evidence stays exact; only the rendering for humans changes.
- **No em-dash, curly quotes, or unicode ellipsis in prose.** Plain ASCII punctuation reads more human, not more academic. Math/technical symbols, en-dash ranges, and anything inside `<pre>`/`<code>` are exempt — this rule is about typographic flourish, not meaningful notation.
