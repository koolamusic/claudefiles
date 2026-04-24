---
description: Draft a GitHub issue from the active sprint's research, plan, or wave — following the evidence-grounded conventions in templates/issue/GUIDE.md. Saves a draft; push is opt-in.
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion
argument-hint: <research|spec|wave> --domain <backend|library|frontend|integration|infra> [--wave <roman>] [--push]
---

Draft a GitHub issue from internal sprint artifacts. The shape decides the template; the domain decides the evidence layer. Default behavior saves a draft to disk; pushing is explicit.

## Parse the input

`$ARGUMENTS` must include:

- **Shape** (positional, required): `research` | `spec` | `wave`
- `--domain <name>` (required): `backend` | `library` | `frontend` | `integration` | `infra`
- `--wave <roman>` (required for `wave` shape): the wave identifier, e.g. `--wave II`
- `--push` (optional): actually create the GitHub issue after drafting
- `--sprint <slug>` (optional): override the active sprint

If shape or domain is missing, use `AskUserQuestion` to collect them (bundle into one question). Do not guess.

## Steps

1. **Locate the sprint.**
   - If `--sprint <slug>` provided, use it.
   - Otherwise `slug=$(cat .jira/CURRENT)`. If empty or missing, stop — there is no active sprint to draw from. Tell the user to run `/jira:research` or pass `--sprint`.

2. **Verify source docs by shape:**
   - `research` — requires `.jira/sprints/<slug>/RESEARCH.md`
   - `spec` — requires at least one `.jira/sprints/<slug>/*-PLAN.md` and `.jira/sprints/<slug>/CONTEXT.md`
   - `wave` — requires the specific `.jira/sprints/<slug>/<NN>-PLAN.md` matching `--wave <roman>`. Map Roman to the NN prefix by reading the `wave:` field in each PLAN's frontmatter. If ambiguous (two plans in the same wave), list them via `AskUserQuestion` and ask which one.

   If a required source is missing, stop and tell the user what to do (`/jira:research` → `/jira:plan` → then `/jira:issue`).

3. **Read the guide and template.**
   - Always read `${CLAUDE_PLUGIN_ROOT}/templates/issue/GUIDE.md` first — it defines the principles and the domain matrix.
   - Then read `${CLAUDE_PLUGIN_ROOT}/templates/issue/<shape>.md`.

4. **Draft the issue body.**

   Fill the template by extracting from the source docs. Apply the domain's section matrix from the GUIDE:

   | Section | backend | library | frontend | integration |
   |---|---|---|---|---|
   | Target Code | ✓ | ✓ | skip unless known | ✓ |
   | Environment | optional | **required** | **required** | optional |
   | Visual evidence | — | — | **required** | sometimes |
   | Workaround | optional | **encouraged** | optional | optional |

   Rules for the draft:
   - **Do not invent evidence.** If the source doc does not contain the file citation, the snippet, or the screenshot reference, write `[TODO: <what's missing>]` and flag it in the report.
   - **Research shape requires Anti-Evidence.** If RESEARCH.md has no weakness section, pull the most likely "this might be wrong because…" from the research findings. If genuinely absent, write `[TODO: anti-evidence — the research did not surface one]` and flag it.
   - **Spec/Wave shapes:** Acceptance criteria must be verifiable (observable outcomes, not "tests pass"). Rewrite any vague criteria or flag them.
   - **Strip marketing language.** GUIDE principle 9.
   - **Title last.** Write the title only after the body is filled, derived from the finished content. Follow the patterns in GUIDE principle 12.

5. **Write the draft file:**

   ```
   .jira/sprints/<slug>/ISSUE-<shape>[-<roman>].md
   ```

   Frontmatter block at the top of the draft:
   ```yaml
   ---
   shape: <research|spec|wave>
   domain: <backend|library|...>
   wave: <roman, if shape=wave>
   sprint: <slug>
   title: <the drafted title>
   status: draft
   ---
   ```

   Body below the frontmatter is the filled template (without the `<!--` guidance comments).

6. **Report to the user before offering to push:**
   - Draft path
   - Drafted title
   - `[TODO: ...]` count, with each one listed
   - Principle-check: any violations found during drafting (e.g. missing anti-evidence on research, vague acceptance on spec)
   - Word count rough guide (flag if < 80 words for research/spec — usually means under-evidenced)

7. **Offer the push decision via `AskUserQuestion`:**

   Question: *"Push this issue to GitHub now?"* with options:
   - **A. Push now** — runs `gh issue create` with the drafted title and body
   - **B. I'll edit the draft first** — exit, user edits `ISSUE-<shape>.md`, reruns `/jira:issue` with `--push` or pushes manually
   - **C. Keep as draft only** — no push, draft stays on disk

   If `--push` was already passed on the command line, skip this question and go straight to push (but still surface the TODO count and principle-check first as a confirmation gate — if any TODOs exist, fall back to the question).

8. **Push (if chosen):**
   ```bash
   gh issue create \
     --title "<title from frontmatter>" \
     --body "$(sed -n '/^---$/,/^---$/!p' <draft-path>)"
   ```

   Capture the new issue number and URL. Append to the draft frontmatter:
   ```yaml
   status: pushed
   issue: <N>
   url: <issue-url>
   pushed_at: <UTC ISO>
   ```

   For `spec` shape with `--push`: also write the issue number back into every `*-PLAN.md` frontmatter (`issue: <N>`) so `/jira:plan` and `/jira:execute` know the issue exists.

9. **Update STATE.md:**
   - Append a line under the sprint's row or in a `## Issues` subsection noting the pushed issue number and shape.
   - Update `last_activity` frontmatter.

10. **Commit:**

    ```bash
    git add .jira/sprints/<slug>/ISSUE-<shape>*.md .jira/STATE.md <any-updated-PLAN.md>
    git commit -m "issue(<slug>): draft <shape> issue for <short-goal>"
    ```

    If pushed, amend the subject to `issue(<slug>): push #<N> <shape> for <short-goal>`.

11. **Final report:**
    - Shape + domain + draft path
    - Title
    - Issue URL (if pushed) or next step ("edit the draft, then rerun with --push")
    - TODOs that remain (if any)

## Hard rules

- **Shape and domain are required.** No guessing. Ask if missing.
- **Evidence must come from source docs.** Invented file:line citations or made-up screenshots are a bug, not a feature. Use `[TODO: ...]` for gaps and flag them.
- **Research issues must have Anti-Evidence** (or an explicit TODO for it, surfaced in the report). Advocacy disguised as investigation is the failure mode.
- **Push is opt-in.** `--push` triggers push; no-flag default is draft-only. Even with `--push`, surface TODO count first and fall back to the question if any exist.
- **Title is derived, not argued.** The user does not pass `--title`. The title is written from the finished body.
- **Don't blend shapes.** Refuse to cram a research + spec into one issue. Tell the user to pick one.
- **STATE.md must be updated** on push, to keep `resume` coherent.
- **Templates + GUIDE live under `${CLAUDE_PLUGIN_ROOT}/templates/issue/`.** Read them fresh every invocation — do not inline their content.
