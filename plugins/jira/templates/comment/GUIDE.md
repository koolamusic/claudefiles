# How to write a GitHub comment

This guide covers **issue comments**, **PR review comments**, **PR/issue close comments**, and short **status updates** posted on GitHub. It is the comment counterpart to [`../author-conventions.md`](../author-conventions.md) and the issue body guide.

**Gold-standard voice:** precise enough for an engineer, clear enough for a stakeholder who has never seen the repo. Pattern: lead with the plain situation, back every load-bearing claim with a clickable permalink, end on one outcome.

## Who you are writing for

Assume the reader:

- has no access to `.jira/`, sprint handoffs, hostnames, or internal chat
- may not know your stack, branch names, or sprint slang
- *can* click a GitHub link and follow a short chain of evidence

If a sentence only makes sense to someone who was in the room, rewrite it.

This guide, including the checklist at the end, is written for **strict mode** — comments on a public repo. On a private or internal repo the bar relaxes; the visibility table in [`../author-conventions.md`](../author-conventions.md) says which of these rules loosen and which never do.

## Voice

1. **Lead with the plain situation.** First 1–2 sentences: what happened / what you decided / what you need, in everyday English.
2. **Then evidence.** Named files, commits, and issue links — not vibes.
3. **Then the ask or next step.** One clear outcome ("closing", "please review X", "blocked on Y").
4. **No hostnames, box nicknames, or vendor infra labels** unless the reader must act on that machine. Prefer "the serving database", "the live read model", "the catch-up host".
5. **No sprint jargon.** No `D-01`, wave labels, worktree paths, `.jira/` filenames, or "the canary agent decided…".
6. **No AI-attribution trailers.**
7. **Prefer "we" / direct statements** over hedging. "Closing — superseded by the current path" beats "It might make sense to potentially consider closing…"

### Good close comment (shape)

> Closing this one — it's outdated relative to how we run things now.
>
> This PR captured tooling from an early catch-up attempt. That work validated the direction, but the throughput bar never cleared, and the matching engine changes never landed as reviewable PRs. The production path today is elsewhere; merging as-is would also roll critical dependencies backward.
>
> Keeping the learnings; not merging the branch.

### Bad close comment

> Closing per operator go. feat-parallelization canary failed perf gate @ 135 l/s; box-B read model is canonical; D-04 / wave II superseded. Refs `.jira/sprints/…`.

## GitHub linking (required)

Always make references clickable the way GitHub itself does. Prefer **permanent** links (commit SHA) over floating branch tips when citing code that must not drift.

### Issues and pull requests

| Intent | In the *same* repo | Across repos |
|---|---|---|
| Mention an issue | `#97` | `owner/other-repo#30` |
| Mention a PR | `#84` or `PR #84` | `owner/other-repo#30` |
| Markdown label | `[#97](https://github.com/OWNER/REPO/issues/97)` | same full URL |
| Close-on-merge (main only) | `Closes #97` / `Fixes #97` | rarely; prefer `Refs` |

Rules:

- Feature / branch PRs use **`Refs #NN`**, not `Closes` — auto-close fires on the promotion-to-main PR ([author-conventions](../author-conventions.md)).
- Cross-repo always use `owner/repo#N` so GitHub creates the backlink.
- When the number alone is ambiguous in prose, spell it: "issue #97", "PR #84".

### Commits

- Short SHA in prose is fine when the repo is obvious: `` `5c4b3be` ``
- Prefer a commit link when a reader might not be in-repo:

```markdown
[`5c4b3be`](https://github.com/OWNER/REPO/commit/5c4b3be)
```

### Code (files and line ranges)

GitHub permalink form:

```text
https://github.com/<owner>/<repo>/blob/<ref>/<path>#L<start>
https://github.com/<owner>/<repo>/blob/<ref>/<path>#L<start>-L<end>
```

- **`<ref>`**: prefer a **full commit SHA** for evidence that must stay true. Use a branch (`main`, `canary`, feature branch) only when you mean "as it stands on that tip".
- Wrap in Markdown so the reader sees a human label:

```markdown
[`internal/store/persist.go`](https://github.com/OWNER/REPO/blob/4e6e970/internal/store/persist.go#L1054)
[`go.mod` L50](https://github.com/OWNER/REPO/blob/4e6e970/go.mod#L50)
[`AuctionState`](https://github.com/OWNER/OTHER-REPO/blob/585cf4e/pkg/types.go#L253-L260)
```

How to mint a permalink quickly:

```bash
# current HEAD of the file you're citing
gh browse <path>:<line> --no-browser
# or:
git rev-parse HEAD
# then build: https://github.com/OWNER/REPO/blob/SHA/path#L10-L20
```

In the GitHub UI: open the file at a commit → click line number(s) → "Copy permalink".

### Same-comment density

A strong comment layers:

1. Plain claim
2. Inline code permalink supporting the claim
3. Related issue/PR autolinks (`#95`, `owner/other-repo#30`)

Do not dump a wall of URLs. One link per load-bearing claim is enough.

## Comment shapes

Pick one; don't mash them together.

| Shape | When | Skeleton |
|---|---|---|
| **Status** | Progress / unblock | Situation → what changed → what's left |
| **Evidence** | Prove or disprove a claim | Claim → linked evidence → reading |
| **Decision** | Close, defer, re-aim | Decision in sentence 1 → why → what happens to the artifact |
| **Ask** | Need a human | One ask → context → options if any |
| **Review note** | PR line/file comment | What you see → why it matters → suggested fix (optional) |

### Decision / close comments

- Say **close** or **merge** explicitly.
- Say whether the *idea* survives ("keeping the learnings") vs the *branch* ("not merging").
- If cleaning related branches, say so in one line — don't narrate every `git` command.

### Review comments

- Prefer specific line permalinks or the GitHub review UI's anchored comment.
- Separate **blocking** vs **suggestion** in the first words.
- Propose a concrete alternative when you block.

## Checklist before posting

- [ ] First two sentences make sense to a stranger
- [ ] Every issue/PR/commit/file citation is a GitHub-native link or autolink
- [ ] Code links pin a **commit SHA** when used as evidence
- [ ] No `.jira/` paths, decision IDs, wave labels, worktree paths
- [ ] No hostnames / vendor box names unless the reader must SSH there
- [ ] No AI trailer
- [ ] One clear outcome (status, decision, or ask)

## Anti-patterns

| Avoid | Prefer |
|---|---|
| "per operator go / baton / handoff" | "we're closing this" / "next step is…" |
| "D-04 locked the substrate" | "we're keeping a single live read model" |
| bare `persist.go:1054` with no link | Markdown permalink to that commit+line |
| `#97` when talking about another repo | `owner/other-repo#97` |
| paste of internal runbook paths | short summary + link to the public issue/PR that holds the runbook |
| "LGTM" with no reading | one sentence on what you actually checked |
