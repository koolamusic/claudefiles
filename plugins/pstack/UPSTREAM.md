# Upstream

| | |
|---|---|
| Source | https://github.com/cursor/plugins |
| Subpath | `pstack/` |
| Commit | `1dcc2bacde73ddd284803b7af28164d0436198fc` |
| Date | 2026-10-12 |
| Version | 0.15.21 |
| License | MIT, (c) 2026 Lauren Tan (`LICENSE`, verbatim) |

## Cut

| Path | Reason |
|---|---|
| `skills/setup-pstack/` | Writes a Cursor `.mdc` rule mapping models to roles. Replaced by the fixed table in `skills/poteto-mode/SKILL.md`. |
| `skills/make-bot-ui/` | Builds a page that wakes a Grok Bot over a Cursor webhook. No Claude Code equivalent. |
| `automations/` | The `benny` issue-triage automation runs on Cursor cloud automations. |
| `docs/`, `assets/` | Cursor-specific guide pages and the logo. `poteto-help` links were retargeted to the skills themselves. |
| `README.md` (upstream) | Describes the Cursor install. Replaced by this plugin's README. |
| `plugin.json`, `.cursor-plugin/`, `.gitignore` | Cursor plugin manifests. Replaced by `.claude-plugin/plugin.json`. |
| `skills/poteto-mode/scripts/orch/`, `scripts/watch-pr/`, `bootstrap.ts`, `package.json`, `bun.lock`, `check-plan.test.ts` | Bun tooling for the Cursor cloud orchestrator and PR watcher. The ported playbooks use the Agent tool and `gh` instead. Kept `check-plan.mjs` and `worktree-audit.sh`, which the playbooks reference. |

## Patch log

Each patch in `patches/` is a diff against the post-cut copy from commit `feat(plugins): vendor pstack from cursor/plugins`. Apply in order with `git apply patches/NN-*.patch`.

| Patch | File | Cursor form | Claude Code form |
|---|---|---|---|
| (filled in by the port commit) | | | |

## Re-vendor

1. Clone the upstream at the new commit: `git clone --depth 1 https://github.com/cursor/plugins /tmp/cursor-plugins && git -C /tmp/cursor-plugins log -1 --format=%H`.
2. Copy `pstack/` into a scratch dir with the cuts above applied (the Cut table is the list; copy the kept paths one by one rather than copying everything and deleting).
3. Reapply the patches in order: `git apply --directory=plugins/pstack patches/*.patch`. A patch that fails to apply means the upstream line changed; reread the upstream file, redo that patch by hand, and regenerate it with `git diff` against the fresh copy.
4. Diff the result against the current tree (`git diff --stat`) and reread every hunk that touches a `model:`, `subagent_type`, or path. Rerun the verification grep from the port commit message.
5. Update the Commit, Date, and Version rows above and bump the `-claude.N` suffix in `.claude-plugin/plugin.json`.
