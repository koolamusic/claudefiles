---
description: Draft or post a GitHub issue/PR comment in stakeholder-readable voice, with proper GitHub autolinks and code permalinks. Default is draft-for-approval; posting is opt-in.
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion
argument-hint: "[--repo owner/name] [--issue N | --pr N] [--close|--decide|--status|--ask|--review] [--post] <notes>"
---

Draft (and optionally post) a GitHub comment. Voice and linking rules live in `${CLAUDE_PLUGIN_ROOT}/templates/comment/GUIDE.md`. Public/internal boundary: `${CLAUDE_PLUGIN_ROOT}/templates/author-conventions.md`.

## Parse the input

`$ARGUMENTS` may include:

- `--repo owner/name` — target repo (default: `gh repo view --json nameWithOwner -q .nameWithOwner` from cwd)
- `--issue N` or `--pr N` — target thread (required unless obvious from conversation)
- Shape hint (optional): `--close` | `--decide` | `--status` | `--ask` | `--review`
- `--post` — actually publish via `gh`; without it, only draft and show the user
- Remaining free text — the substance of the comment (decision, evidence, ask)

If the target (`--issue` / `--pr`) or the substance is missing and cannot be inferred from the conversation, use `AskUserQuestion` once. Do not invent a decision.

## Steps

1. **Read the guides** (every run):
   - `${CLAUDE_PLUGIN_ROOT}/templates/comment/GUIDE.md`
   - `${CLAUDE_PLUGIN_ROOT}/templates/author-conventions.md`

2. **Resolve the thread.** Fetch enough context to avoid writing past the current state:
   ```bash
   gh issue view N --repo OWNER/REPO --json title,state,body,comments
   # or
   gh pr view N --repo OWNER/REPO --json title,state,body,comments,commits
   ```
   Skim the latest comments. Do not contradict a newer disposition without acknowledging it.

3. **Resolve permalinks before drafting.**
   - For every file/line you cite: get a commit SHA (`git rev-parse HEAD` in that repo, or the SHA named in evidence) and build:
     `https://github.com/OWNER/REPO/blob/<sha>/<path>#L<start>-L<end>`
   - Same-repo issues/PRs → `#N`. Cross-repo → `owner/repo#N`.
   - Prefer SHA-pinned code links for evidence; branch tips only when you mean "as of this tip".

4. **Draft the comment** per GUIDE:
   - Lead with the plain situation (1–2 sentences a stranger can parse)
   - Evidence with clickable links
   - One clear outcome (status / decision / ask)
   - Strip: hostnames, vendor box names, `.jira/` paths, decision IDs, wave labels, worktree paths, AI trailers
   - Feature PRs: `Refs #N`, never `Closes` (author-conventions)

5. **Show the draft to the user** as a fenced markdown block, plus:
   - Target: `OWNER/REPO#N` (issue or PR)
   - Shape used
   - Link checklist (issues, PRs, commits, code) — confirm each resolves

6. **Post only with `--post` or explicit user approval.** Then:
   ```bash
   # issue comment
   gh issue comment N --repo OWNER/REPO --body "$(cat <<'EOF'
   …draft…
   EOF
   )"

   # PR comment
   gh pr comment N --repo OWNER/REPO --body "$(cat <<'EOF'
   …draft…
   EOF
   )"

   # close with comment (only when shape is --close/--decide and user confirmed)
   gh pr close N --repo OWNER/REPO --comment "…"
   # or: gh issue close N --repo OWNER/REPO --comment "…"
   ```
   Return the comment URL.

## Defaults

- **Draft-first.** Never post silently.
- **Humanize.** If the user's notes are internal jargon, translate; keep technical accuracy in the links.
- **One comment, one job.** Don't mix a close decision with a new feature proposal.
- If editing a comment you just posted in this session, `gh api -X PATCH …/issues/comments/{id}` is fine — do not silently rewrite other people's comments.
