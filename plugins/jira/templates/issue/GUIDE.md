# How to write an issue

This guide teaches jira how to write GitHub issues that reflect an internal **research**, **plan**, or **wave** spec. It is grounded in observed conventions from three repos, one per domain:

- [**stellar/wallet-backend**](https://github.com/stellar/wallet-backend/issues) — backend / data-pipeline. The H-series hypotheses set the bar for evidence-grounded investigation.
- [**vercel-labs/json-render**](https://github.com/vercel-labs/json-render/issues) — TypeScript library. Contributor bug reports show the pattern for library/API issues (Minimal Reproduction, Environment, Workaround).
- [**stellar/freighter-mobile**](https://github.com/stellar/freighter-mobile/issues) — mobile wallet. Visual/UX bugs use a fixed template; integration bugs (e.g. #812) adapt the H-series shape across systems.

Read a few issues from the domain you are writing for before drafting. Pattern-match the tone.

## The three shapes

A **shape** is *what kind of thing* the issue represents. Shapes are orthogonal to domains.

| Shape | Source doc | When to use |
|---|---|---|
| `research` | `RESEARCH.md` | A hypothesis or finding — something you believe is true about the system. Use when the work is about **proving or disproving** a claim, not yet about building. |
| `spec` | all `*-PLAN.md` + `CONTEXT.md` | A sprint-level proposal — the shape of the work you intend to do. Use when you want the team to see the full arc before execution. |
| `wave` | one `NN-PLAN.md` | A single executable slice — a concrete wave within a plan. Use to track and assign one wave at a time. |

Each shape has its own template under `templates/issue/`. Don't blur them — a "spec with embedded research" loses both.

## The five domains

A **domain** is *what kind of code/surface* the issue touches. The shape stays the same; the **evidence layer** changes.

| Domain | Evidence primitive | Example |
|---|---|---|
| `backend` | `path/to/file.ext:L-L` + code snippet | stellar/wallet-backend H-series |
| `library` | Minimal runnable reproduction + Environment + Root cause (file:line) | json-render #196, #231, #251 |
| `frontend` | Version + What did you do / expect / see + screenshot or video | freighter-mobile #719, #806 |
| `integration` | Current behavior (file:line in owned system) + Expected behavior (external API ref) + Related (cross-repo) | freighter-mobile #812 |
| `infra` | Logs + runbook/config ref + environment (prod/staging/branch) | follow the spirit; no template prescribed |

The templates carry domain hints — pick the domain per issue and fill the evidence block accordingly.

## Principles (universal — apply to all shapes and domains)

### 1. Evidence over assertion

Every non-trivial claim has a citation. Form of citation depends on domain (see matrix above), but a reader should be able to verify any load-bearing sentence in under a minute.

**Good (backend):** `insertIntoDB does not touch the balance models (internal/services/ingest_backfill.go:601-659).`

**Good (library):** A runnable 15-line snippet that reproduces the issue when pasted into a fresh repo.

**Good (frontend):** Version + repro steps + a screenshot showing the broken state.

**Bad (any domain):** `The ingestion logic has a consistency problem.`

### 2. Anti-evidence is mandatory for research issues

Every hypothesis has a reason it might be wrong. Write it. The H-series calls this `## Anti-Evidence` and it is the single strongest signal that the author thought hard. An issue without anti-evidence reads as advocacy; an issue with it reads as investigation.

If you genuinely can't think of anti-evidence, the issue is either trivially true or you haven't looked hard enough. Do not skip this section on a research issue.

For `spec` and `wave` shapes, the equivalent is a `## Risks` or `## Open Questions` section — same discipline, different name.

### 3. Mechanism, not symptom

Describe **why** the behavior happens, at the level of named functions, data shapes, control flow, or user-visible states. Do not describe the symptom and stop.

- **Backend/library:** `The multi-key branch in operationsByToIDLoader reads only keys[0] and ignores the rest.`
- **Frontend:** `The icon component renders before the token metadata resolves; the fallback path defaults to the native-asset icon.`
- **Integration:** `Horizon's max_fee.mode is computed across classic and Soroban transactions together; Soroban fees do not surface separately.`

A reader should finish the Mechanism section understanding the failure in the same terms they'd use to fix it.

### 4. Reproduction is a steps-list, not a guess

- **Backend:** The minimal state + request that exhibits the bug. Include the exact inputs.
- **Library:** A **runnable code snippet**. Not pseudocode. Paste-into-a-file-and-run. This is the single most-cited norm from json-render contributors — it is the thing the maintainer will actually execute.
- **Frontend:** Version, numbered steps, expected-vs-actual, screenshot/video. Follow the GitHub issue template convention exactly.
- **Integration:** The cross-system scenario — which system initiates, which system receives, which system observes the bad state.

If the bug is speculative (no repro yet), say so in Anti-Evidence and keep the Trigger as the *shape* of a repro — not a handwave.

### 5. Environment is part of evidence (library / frontend)

For library and frontend issues, the exact versions are load-bearing. Include:

- Package version(s) — `@json-render/core@0.14.1`
- Runtime — `Node.js 22.16.0`, `iOS v1.14.25`
- Adjacent tools — `Zod 4.3.5`, `Claude Sonnet 4.6 via Cloudflare AI Gateway`

Backend/integration issues typically don't need this (the repo has one prod config), but include it if the bug is version-specific.

### 6. Severity and Impact are orthogonal

**Severity** (Low / Medium / High / Critical) — how bad is the worst case.
**Impact** (Availability / Integrity / Performance / Security / UX / Correctness) — what dimension is affected.

A Medium/Integrity is different from a Medium/Availability, and the fix priority depends on which dimension the product cares about. Set both on research and bug issues. On spec/wave issues, set neither — the risk surface belongs in `## Risks`.

### 7. Target Code is a map, not a grep dump

For backend/library/integration domains, list the 3-6 lines (or ranges) that are load-bearing for the claim. Annotate each with what lives there. Orient the reader to the smallest set of places they need to read — not every related line.

**Good:**
```
- `internal/services/checkpoint.go:503-548` — calls `MustInstance()` without ok check
- `internal/indexer/processors/protocol_contracts.go:66-73` — live indexer handles the same case safely with `GetInstance()`
```

**Bad:** a wall of 30 file paths with no annotation.

For frontend visual bugs, this section is usually not useful — the screenshot IS the target. Skip it unless you genuinely know which component file is at fault.

### 8. Scope must match the shape

- **Research issues** are single-hypothesis. One bug, one concern, one finding. Two hypotheses = two issues.
- **Spec issues** are sprint-scoped. One plan, one issue. Sub-waves are referenced but not duplicated inline.
- **Wave issues** are single-slice. One wave, ≤ 3 tasks, one issue.

Do not blend shapes.

### 9. No marketing language

These are engineering issues, not launch copy. Strike: *seamlessly, robustly, significantly, elegantly, powerful, next-gen, best-in-class*. Replace with the concrete number or behavior the word was gesturing at. If there is no concrete behind the word, the word was filler.

### 10. Honest uncertainty

If a claim is a guess, mark it. The H-series metadata header uses `Hypothesis by: <model>, <confidence>` — e.g. `gpt-5.4, high` vs `gpt-5.4, low`. Low-confidence hypotheses are still worth filing; dishonest-confidence hypotheses are not.

Frontend contributors show this as open questions ("Is this intentional?" — json-render #222, #224). Steal that pattern.

### 11. Workaround if you have one

If you found a way around the issue, share it. This is standard in json-render contributor issues and it:

- Unblocks other users who hit the same thing while you wait for a fix
- Signals to the maintainer that you tried before filing
- Constrains the fix space (any fix must not break the workaround people now rely on)

Put it under `## Workaround` near the end, after Expected Behavior but before Environment.

### 12. Keep the title load-bearing

The title should survive being the only thing a triager reads. It names the subsystem, the behavior, and (for research) the hypothesis in one line.

**Good:**
- `H008: Transaction.operations Aliases Collapse to One Page Definition` (backend research)
- `catalog.validate() silently strips on, repeat, watch, and state from specs` (library bug)
- `FaceID icon does not render during onboarding` (frontend visual)
- `Use Stellar RPC getFeeStats for Soroban fee calculation instead of Horizon feeStats` (integration)

**Bad:**
- `Bug in GraphQL`
- `Improve performance`
- `Fix the icon`

## Domain → section matrix

When filling a template, use the domain to decide which evidence sections to include:

| Section | backend | library | frontend | integration |
|---|---|---|---|---|
| Expected Behavior | ✓ | ✓ | ✓ (What did you expect to see) | ✓ |
| Mechanism / Root Cause | ✓ | ✓ | optional | ✓ |
| Trigger / Reproduction | ✓ (repro steps) | ✓ (runnable snippet) | ✓ (version + numbered steps) | ✓ (cross-system scenario) |
| Target Code | ✓ | ✓ | skip unless known | ✓ (may span repos) |
| Visual evidence (screenshot/video) | — | — | **required** | sometimes |
| Environment | optional | **required** | **required** | optional |
| Evidence | ✓ | ✓ | implicit (the screenshot) | ✓ |
| Anti-Evidence (research only) | ✓ | ✓ | ✓ | ✓ |
| Workaround | optional | **encouraged** | optional | optional |
| Related (cross-repo) | optional | optional | optional | **encouraged** |

## Drafting motion

1. Read the source doc (`RESEARCH.md`, the PLAN files, or one wave PLAN).
2. Pick the **shape** (research / spec / wave). Load the matching template.
3. Pick the **domain** (backend / library / frontend / integration / infra). Apply the section matrix.
4. Fill the template top-down. Start with the evidence you have; let the claim follow from it.
5. Pass over the draft once for each principle above. Anti-evidence first — it usually exposes the weakest section.
6. Strip marketing language. Strip redundancy. Strip headers with nothing under them.
7. Write the title last, from the finished body.

## Before pushing

- Every file citation resolves (grep it).
- Every D-XX reference exists in CONTEXT.md.
- For library/frontend: the minimal reproduction was actually run — don't ship untested repros.
- For frontend: the screenshot/video is attached and shows the specific state being described.
- Severity and Impact are set (research shape).
- Acceptance criteria are verifiable (spec / wave shape) — "the tests pass" is not acceptance, "`account.balances` returns the same ledger as `account.transactions` during catchup" is.
- The title survives being read in isolation.
- Anti-evidence (or Risks / Open Questions) exists and is real.

If any of the above fails, do not push. Revise or escalate to the user.
