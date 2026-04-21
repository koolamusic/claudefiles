# studio

Studio moves workflow state (`.planning/`, `.retrospective/`, `.uat/`, `.jira/`, local memory) out of project repos into a single private git repo at `~/.studio/`. Project roots get symlinks pointing into per-project subdirs. Tools and skills that expect `.planning/`, `.jira/`, etc. see exactly those paths — no modifications needed.

## Commands

| Command | Purpose |
|---|---|
| `/studio:setup` | Initialize the current project against `~/.studio/<slug>`: create workspace dirs, move existing state, write symlinks, sync the managed `.gitignore` block (which also gitignores `.workspacerc` as a machine-local breadcrumb), write `.workspacerc` at the project root. |
| `/studio:sync` | Re-sync the managed `.gitignore` block and validate symlinks. Idempotent; safe no-op on a healthy project. |

## Workspace layout

```
~/.studio/
├── studio.yaml
├── README.md
└── <project-slug>/
    ├── jira/
    ├── planning/
    ├── retrospective/
    ├── uat/
    ├── skills/
    └── hooks/
```

## Project-root effects

- `.workspacerc` — gitignored via the managed block; machine-local breadcrumb pointing at the workspace.
- `.jira`, `.planning`, `.retrospective`, `.uat` — symlinks into `~/.studio/<slug>/`, gitignored via the studio-managed block.
- `.gitignore` — gains a studio-managed block delimited by markers; Studio owns the contents between the markers and replaces it wholesale on sync.

## Install

This plugin ships with the [koolamusic/claudefiles](https://github.com/koolamusic/claudefiles) marketplace. From a Claude Code session:

```
/plugin install studio@claudefiles
```

## Hard rules

- **Never auto-push.** Studio operates on the local `~/.studio/` repo; publishing is the user's call.
- **Idempotent.** `/studio:setup` and `/studio:sync` converge to the same state on repeated runs; no duplicated gitignore blocks, no layered symlinks.
- **`studio.yaml` is the source of truth.** Symlink map, workspace dirs, and the managed gitignore block all derive from it.
- **Managed block replaced wholesale.** Studio owns the content between its markers end-to-end; manual edits inside the block will be overwritten on sync.
- **Conflicts stop and ask.** If a project-root path already exists as a real file/dir (not a symlink to the expected workspace target), Studio halts and surfaces the conflict rather than clobbering user data.

## Not in P1

- Memory archival
- `/studio:adopt`
- Workspace `CLAUDE.md` template
- `/studio:migrate`
