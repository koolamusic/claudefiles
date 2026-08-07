# GitHub sprint tracking — design note

Status: shaped, not built.

## The need

Read a sprint's research and plans (markdown + mermaid) and leave a comment,
from the GitHub mobile app, while sprints pile up over time and none get deleted.

That's the whole capability. Everything below serves exactly that.

## Shape

**Content stays canonical as local markdown** in the studio repo — research,
plans, verification. Pushed to GitHub so the app renders it. No content moves
into issue bodies; the git files remain the source of truth (grep, offline,
diff, portability all preserved).

**Lifecycle without deletion.** Each sprint carries a `status:` field
(`active` → `shipped` → `retired`) and retired sprints move to
`sprints/archive/`. Out of the live tree, still in git, still greppable.

**Two GitHub surfaces, granularity follows lifecycle — not comment convenience:**

```
Sprint issue (parent)            ← one per sprint
├─ pointer to RESEARCH.md, VERIFICATION.md, CONTEXT.md  (links, not their own issues)
├─ general sprint comments live here
└─ task-list of plan issues:
   - [ ] #12  Wave I  → 01-PLAN.md → closing PR
   - [ ] #13  Wave II → 02-PLAN.md → closing PR

Plan issue (child)               ← one per wave-plan
├─ pointer to its NN-PLAN.md
├─ plan-specific comments
└─ closes when its PR lands
```

- **Plans get their own issue** because they have an independent open→close arc
  (executed, closed by a PR, mapped to a main-repo task). Wave I can close while
  Wave II is still open.
- **Research / verification / context do not** — they are read-artifacts with no
  lifecycle. They hang off the sprint issue as links. A per-artifact issue would
  buy nothing but another surface to manage and another place a comment can orphan.

Parent→child link is a plain `- [ ] #N` task-list in the sprint issue body —
GitHub renders the relationship natively, no special tooling. (GitHub sub-issues
exist but are GraphQL-only via CLI — confirm support before leaning on them.)

## Hard rules

- **Permalinks, never autolinks.** Every cross-reference (external task, closing
  PR, file citation) is a full `https://` URL, never `owner/repo#N`. Two reasons:
  cross-repo closing keywords are inert (a project-repo PR cannot auto-close a
  studio-repo issue), and an `owner/repo#N` autolink from a public project repo
  would leak the private studio issue's existence into the public timeline.
- **Issues are regenerable projections.** The issue body is rebuildable from the
  sprint folder anytime. Files are truth; the issue is a view with a comment
  thread attached.
- **Comments are the one non-regenerable part.** Never delete an issue, only
  close it. When a comment turns load-bearing, harvest it back into the sprint's
  `RETRO.md` or `STATE.md` so the canonical record absorbs it.

## Where it lives

Sprint issues live in the **studio repo** (`koolamusic/studio` by default,
configurable in `studio.yaml`). Execution/task issues stay in the **project
repo** where the code and PRs live. The sprint issue links out to the project
issue via permalink.

## Deferred — do not build until a real sprint proves the need

Recorded here so the design doesn't get rebuilt on momentum. None of these are
wrong; all are speculative until friction shows up.

- **Sprints as YAML-only, content on GitHub.** Trades grep/offline/portability
  for a byte-load that doesn't exist. Cuts against studio's reason to exist
  (state in a repo you control).
- **Three-tier raw → studio-derived → main-repo derivation.** Two drift
  surfaces, two comment-orphan surfaces. Build the flat version first.
- **"Front-facing derived version for stakeholders."** The studio repo is
  private; its only reader is you. Serves an audience that doesn't exist yet.
- **Cross-client confidentiality architecture.** One studio repo holding sprint
  issues across clients is fine while single-viewer. Only matters if that repo
  is ever shared — solve it then.
- **GitHub Discussions instead of issues.** Better conceptual fit (categories,
  threads, no false task semantics) but weaker CLI ergonomics (GraphQL, not a
  one-liner). Revisit if issue proliferation in the studio repo starts to bite.

## Build order when picked up

1. Lifecycle + archival (`status:` field, `sprints/archive/`, retire move). Local
   only, no GitHub. Solves the original noise pain on its own.
2. Sprint issue generator (pointer body + task-list of plans) — opt-in.
3. Plan issue generator, wired to the execute→PR flow so each plan issue closes
   with its PR.

studio and jira collaborate here: studio owns the repo target and workspace;
jira owns the sprint lifecycle and the generators. `gh` CLI is the mechanism.
