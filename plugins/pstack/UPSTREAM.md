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

- `01-tool-names.patch`: 19 edits
- `02-agent-names.patch`: 5 edits
- `03-frontmatter.patch`: 2 edits
- `04-paths.patch`: 23 edits
- `05-models.patch`: 22 edits
- `06-cursor-neighbors.patch`: 55 edits
- `07-cloud-playbooks.patch`: 26 edits
- `08-poteto-help.patch`: 19 edits
- `09-wording.patch`: 3 edits

Line numbers are in the file as it stood before that patch. Snippets are truncated; the patch files carry the full hunks. `skills/poteto-mode/references/bugbot-triage.md` was dropped in the port commit because nothing referenced it after the Cursor-neighbor strip (the file is renamed with a `prune_` prefix until the owner prunes it).

| Patch | File | Line | Cursor form | Claude Code form |
|---|---|---|---|---|
| 01-tool-names | `skills/poteto-mode/SKILL.md` | 22 | About to `AskQuestion` on | About to `AskUserQuestion` on |
| 01-tool-names | `skills/poteto-mode/playbooks/autonomous-run.md` | 9 | or use `AskQuestion`. | or use `AskUserQuestion`. |
| 01-tool-names | `skills/automate-me/SKILL.md` | 17 | confirm intent with `AskQuestion` | confirm intent with `AskUserQuestion` |
| 01-tool-names | `skills/automate-me/SKILL.md` | 44 | Use the `AskQuestion` tool (structured multi-choice) | Use the `AskUserQuestion` tool (structured multi-choice) |
| 01-tool-names | `agents/poteto-agent.md` | 9 | the todo list, and every Task spawn. | the todo list, and every Agent tool spawn. |
| 01-tool-names | `agents/poteto-agent.md` | 3 | Substituting `generalPurpose` skips that read and drifts. | Substituting `general-purpose` skips that read and drifts. |
| 01-tool-names | `skills/poteto-mode/playbooks/opening-a-pr.md` | 5 | Multiple `Task` calls on the same branch | Multiple Agent tool calls on the same branch |
| 01-tool-names | `skills/no-comments/SKILL.md` | 19 | 1. Spawn `Task` with `subagent_type: "comment-sicko"`. | 1. Spawn an Agent tool subagent with `subagent_type: "pstack:comment-sicko"`. |
| 01-tool-names | `skills/reflect/SKILL.md` | 25 | One message, three `Task` calls, `subagent_type: generalPurpose`, agent mode (`readonly: … | One message, three Agent tool calls, `subagent_type: "general-purpose"`. Reviewers need M… |
| 01-tool-names | `skills/reflect/SKILL.md` | 35 | Reviewers return findings in the `Task` response body. | Reviewers return findings in their final report. |
| 01-tool-names | `skills/reflect/SKILL.md` | 39 | One `Task` call, `subagent_type: generalPurpose`, `model` from the `reflect judgment, div… | One Agent tool call, `subagent_type: "general-purpose"`, no `model` (the `reflect judgmen… |
| 01-tool-names | `skills/reflect/references/tooling-reviewer.md` | 31 | a `Task` prompt naming its path | an Agent tool prompt naming its path |
| 01-tool-names | `skills/reflect/references/judgment-reviewer.md` | 20 | a `Task` prompt naming its path | an Agent tool prompt naming its path |
| 01-tool-names | `skills/reflect/references/divergent-reviewer.md` | 21 | a `Task` prompt naming its path | an Agent tool prompt naming its path |
| 01-tool-names | `skills/why/SKILL.md` | 13 | Every spawn is `generalPurpose` with `readonly: false` (agent mode). **Do not use readonl… | Every spawn is `subagent_type: "general-purpose"`, which keeps MCP access for the MCP-bac… |
| 01-tool-names | `skills/how/SKILL.md` | 11 | Every spawn is a Task subagent with `subagent_type: generalPurpose` and `readonly: true`. | Every spawn is an Agent tool subagent with `subagent_type: "general-purpose"`, told to wr… |
| 01-tool-names | `skills/interrogate/SKILL.md` | 27 | Launch all reviewers in a single message with the Task tool, | Launch all reviewers in a single message with the Agent tool, |
| 01-tool-names | `skills/poteto-mode/playbooks/orchestrate.md` | 15 | Agents are spawned, resumed, and drained only through the Task tool. State reads and writ… | Agents are spawned and drained only through the Agent tool. State reads and writes edit t… |
| 01-tool-names | `skills/poteto-mode/playbooks/orchestrate.md` | 16 | a nested spawn has the full Task schema including `environment` | a nested spawn has the full Agent tool schema including `isolation` |
| 02-agent-names | `skills/poteto-mode/SKILL.md` | 13 | Bundled skills live at `../<name>/SKILL.md` from this file, so put this file's absolute p… | Bundled skills live at `../<name>/SKILL.md` from this file. Every `pstack:poteto-agent` p… |
| 02-agent-names | `skills/poteto-mode/SKILL.md` | 95 | **Use `subagent_type: "poteto-agent"` for any subagent you spawn inside a playbook step**… | **Use `subagent_type: "pstack:poteto-agent"` for any subagent you spawn inside a playbook… |
| 02-agent-names | `agents/poteto-agent.md` | 9 | Read the `poteto-mode` skill's `SKILL.md` in full before doing any work, including its in… | Read the `poteto-mode` skill's `SKILL.md` in full before doing any work, including its in… |
| 02-agent-names | `skills/poteto-mode/playbooks/multi-phase-plan.md` | 7 | 3. Explore in subagents with `subagent_type: "poteto-agent"` and an explicit model per th… | 3. Explore in subagents with `subagent_type: "pstack:poteto-agent"` and an explicit model… |
| 02-agent-names | `skills/poteto-help/SKILL.md` | 57 | `/poteto-mode` already uses `poteto-agent` for the subagents its playbook steps spawn. To… | `/poteto-mode` already uses `pstack:poteto-agent` for the subagents its playbook steps sp… |
| 03-frontmatter | `skills/poteto-mode/SKILL.md` | 4 | disable-model-invocation: true / mode: true / icon: crown / color: yellow / reminder: New… | disable-model-invocation: true / --- |
| 03-frontmatter | `agents/poteto-agent.md` | 3 | Substituting `general-purpose` skips that read and drifts. / is_background: true / --- | Substituting `general-purpose` skips that read and drifts. / --- |
| 04-paths | `skills/recall/SKILL.md` | 15 | Transcripts live at `~/.cursor/projects/<slug>/agent-transcripts/<uuid>/<uuid>.jsonl`, wh… | Transcripts live at `~/.claude/projects/<slug>/<session-id>.jsonl`, where `<slug>` is the… |
| 04-paths | `skills/reflect/SKILL.md` | 15 | Before fanning out, find this conversation's transcript in the `agent-transcripts/` direc… | Before fanning out, find this conversation's transcript under `~/.claude/projects/<slug>/… |
| 04-paths | `skills/reflect/SKILL.md` | 18 | ls -t <agent-transcripts>/*.jsonl <agent-transcripts>/*/*.jsonl <agent-transcripts>/*/sub… | ls -t ~/.claude/projects/<slug>/*.jsonl ~/.claude/projects/<slug>/*/subagents/*.jsonl 2>/… |
| 04-paths | `skills/reflect/SKILL.md` | 21 | That covers the legacy flat (`<id>.jsonl`), current nested (`<id>/<id>.jsonl`), and subag… | That covers the session (`<id>.jsonl`) and subagent (`<parent>/subagents/agent-<child>.js… |
| 04-paths | `skills/reflect/references/tooling-reviewer.md` | 31 | (under `.cursor/skills/`, `~/.cursor/skills/`, or `~/.cursor/plugins/`) | (under `.claude/skills/`, `~/.claude/skills/`, or `~/.claude/plugins/`) |
| 04-paths | `skills/reflect/references/judgment-reviewer.md` | 20 | (under `.cursor/skills/`, `~/.cursor/skills/`, or `~/.cursor/plugins/`) | (under `.claude/skills/`, `~/.claude/skills/`, or `~/.claude/plugins/`) |
| 04-paths | `skills/reflect/references/divergent-reviewer.md` | 21 | (under `.cursor/skills/`, `~/.cursor/skills/`, or `~/.cursor/plugins/`) | (under `.claude/skills/`, `~/.claude/skills/`, or `~/.claude/plugins/`) |
| 04-paths | `skills/show-me-your-work/SKILL.md` | 57 | Read this run's transcript under the active workspace's `agent-transcripts/` directory (t… | Read this run's transcript under `~/.claude/projects/<slug>/`, where `<slug>` is the work… |
| 04-paths | `skills/poteto-mode/playbooks/session-pickup.md` | 5 | A local transcript under the active workspace's `agent-transcripts/` directory (the syste… | A local transcript under `~/.claude/projects/<slug>/`, where `<slug>` is the workspace's … |
| 04-paths | `skills/poteto-mode/playbooks/eval.md` | 22 | Read each candidate's local transcript under the active workspace's `agent-transcripts/` … | Read each candidate's local transcript under `~/.claude/projects/<slug>/`, where `<slug>`… |
| 04-paths | `skills/poteto-mode/playbooks/worktree-cleanup.md` | 3 | misses one that lives at `.cursor/worktrees/myrepo/x` | misses one that lives at `.claude/worktrees/myrepo/x` |
| 04-paths | `skills/poteto-mode/playbooks/worktree-cleanup.md` | 8 | Xcode `DerivedData` and `iOS DeviceSupport`, `~/Library/Application Support/Cursor` (`sta… | Xcode `DerivedData` and `iOS DeviceSupport`, package caches |
| 04-paths | `skills/create-verification-skill/SKILL.md` | 9 | as a project-local skill (`.cursor/skills/verify-<app>/`) | as a project-local skill (`.claude/skills/verify-<app>/`) |
| 04-paths | `skills/create-verification-skill/SKILL.md` | 25 | Write `.cursor/skills/verify-<app>/SKILL.md` with YAML frontmatter | Write `.claude/skills/verify-<app>/SKILL.md` with YAML frontmatter |
| 04-paths | `skills/create-verification-skill/SKILL.md` | 36 | Create `.cursor/skills/verify-<app>/features/README.md` | Create `.claude/skills/verify-<app>/features/README.md` |
| 04-paths | `skills/maintain-verification-skill/SKILL.md` | 25 | (usually `.cursor/skills/verify-*/`) | (usually `.claude/skills/verify-*/`) |
| 04-paths | `skills/automate-me/SKILL.md` | 17 | Look recursively for `.cursor/skills/**/*-mode/SKILL.md` and `~/.cursor/skills/*-mode/SKI… | Look recursively for `.claude/skills/**/*-mode/SKILL.md` and `~/.claude/skills/*-mode/SKI… |
| 04-paths | `skills/automate-me/SKILL.md` | 29 | Locate the active workspace's transcripts before fanning out. The system prompt names the… | Locate the active workspace's transcripts before fanning out. They live under `~/.claude/… |
| 04-paths | `skills/automate-me/SKILL.md` | 69 | For a new mode, use `.cursor/skills/<handle>/<handle>-mode/SKILL.md` when the repo has an… | For a new mode, use `.claude/skills/<handle>/<handle>-mode/SKILL.md` when the repo has an… |
| 04-paths | `skills/poteto-mode/playbooks/multi-phase-plan.md` | 10 | 6. Run `node pstack/skills/poteto-mode/scripts/check-plan.mjs <plan.md>` | 6. Run `node ${CLAUDE_PLUGIN_ROOT}/skills/poteto-mode/scripts/check-plan.mjs <plan.md>` |
| 04-paths | `skills/poteto-mode/playbooks/multi-phase-plan.md` | 8 | Unless the operator names a path, write the file under the agent store's `docs/`. | Unless the operator names a path, write the file under the repo's `docs/plans/`. |
| 04-paths | `skills/why/SKILL.md` | 23 | (open files, recent edits, cursor location, what was just discussed) | (open files, recent edits, caret position, what was just discussed) |
| 04-paths | `skills/why/SKILL.md` | 35 | Before spawning investigators, list the available MCPs from the Cursor environment. Use t… | Before spawning investigators, list the available MCP servers: the `mcp__<server>__*` too… |
| 05-models | `skills/poteto-mode/SKILL.md` | 91 | Routed workflow skills (`how`, `why`, `interrogate`, `reflect`, `swarm`) set their own `s… | Routed workflow skills (`how`, `why`, `interrogate`, `reflect`, `swarm`) set their own `s… |
| 05-models | `skills/poteto-mode/SKILL.md` | 93 | **Defaults for every `Task` call.** `run_in_background: true`, agent mode (readonly strip… | **Defaults for every Agent tool call.** `run_in_background: true`, file pointers not inli… |
| 05-models | `skills/poteto-mode/playbooks/feature.md` | 12 | using your configured feature model (default `grok-4.7-xhigh-fast`) | with `model: "sonnet"` (the `feature and refactoring` role) |
| 05-models | `skills/poteto-mode/playbooks/refactoring.md` | 11 | using your configured refactoring model (default `grok-4.7-xhigh-fast`) | with `model: "sonnet"` (the `feature and refactoring` role) |
| 05-models | `skills/poteto-mode/playbooks/bug-fix.md` | 9 | using your configured bug-fix model (default `grok-4.7-xhigh-fast`) | with `model: "sonnet"` (the `bug-fix` role) |
| 05-models | `skills/poteto-mode/playbooks/perf-issue.md` | 17 | using your configured perf-issue model (default `grok-4.7-xhigh-fast`) | with `model: "sonnet"` (the `perf-issue` role) |
| 05-models | `skills/poteto-mode/playbooks/hillclimb.md` | 12 | using your configured hillclimb model (default `grok-4.7-xhigh-fast`) | with `model: "sonnet"` (the `hillclimb` role) |
| 05-models | `skills/poteto-mode/playbooks/multi-phase-plan.md` | 13 | on the `swarm workers` model (default `grok-4.7-xhigh-fast`) | on the `swarm workers` model (`sonnet`) |
| 05-models | `skills/how/SKILL.md` | 11 | Explorers use the `how explorer` line in the `pstack-models.mdc` rule (default `grok-4.7-… | Explorers run on `model: "sonnet"` (the `how explorer` role). Explainers omit `model` and… |
| 05-models | `skills/why/SKILL.md` | 11 | Each spawn below names a role line in the `pstack-models.mdc` rule and a default. Set `mo… | Each spawn below names its role from the model table in the `poteto-mode` skill. |
| 05-models | `skills/why/SKILL.md` | 49 | `model`: the `why investigators` line, default `grok-4.7-xhigh-fast`. | `model: "sonnet"` (the `why investigators` role). |
| 05-models | `skills/why/SKILL.md` | 79 | Spawn one synthesizer. `model`: the `why synthesizer` line, default `claude-opus-5-5-xhig… | Spawn one synthesizer with no `model` (the `why synthesizer` role inherits the parent). I… |
| 05-models | `skills/reflect/SKILL.md` | 27 | Each reviewer and the synthesizer name a role line in the `pstack-models.mdc` rule and a … | Each reviewer and the synthesizer name a role from the model table in the `poteto-mode` s… |
| 05-models | `skills/reflect/SKILL.md` | 29 | \| Lens \| Role line \| Default `model` \| Prompt template \| / \|---\|---\|---\|---\| / … | \| Lens \| Role \| `model` \| Prompt template \| / \|---\|---\|---\|---\| / \| Judgment \… |
| 05-models | `skills/interrogate/SKILL.md` | 27 | one per entry on the `interrogate reviewers` line in `~/.cursor/rules/pstack-models.mdc`,… | one per entry on the `interrogate reviewers` row of the model table in the `poteto-mode` … |
| 05-models | `skills/interrogate/SKILL.md` | 3 | \"multi-model review\", | \"cross-tier review\", |
| 05-models | `skills/interrogate/SKILL.md` | 9 | The adversarial signal comes from model diversity, not assigned personas. | The adversarial signal comes from the cross-tier reviewers, not assigned personas. |
| 05-models | `skills/arena/SKILL.md` | 17 | 3. Pick the runners. Use the `arena runners` line in `~/.cursor/rules/pstack-models.mdc`.… | 3. Pick the runners. The `arena runners` row of the model table in the `poteto-mode` skil… |
| 05-models | `skills/arena/SKILL.md` | 28 | choose one model from the `arena cross-judge pool` line in `~/.cursor/rules/pstack-models… | choose one model from the `arena cross-judge pool` row of the model table in the `poteto-… |
| 05-models | `skills/architect/SKILL.md` | 31 | Take the runners from the `architect runners` line in the `pstack-models.mdc` rule, in pl… | Take the runners from the `architect runners` row of the model table in the `poteto-mode`… |
| 05-models | `skills/swarm/SKILL.md` | 25 | 4. Pick the worker model from the `swarm workers` line in `~/.cursor/rules/pstack-models.… | 4. The worker model is `sonnet` (the `swarm workers` row of the model table in the `potet… |
| 05-models | `skills/swarm/SKILL.md` | 30 | Spawn all N workers in one message with `subagent_type: generalPurpose`, `environment: "c… | Spawn all N workers in one message with `subagent_type: "general-purpose"`, `run_in_backg… |
| 06-cursor-neighbors | `skills/poteto-mode/SKILL.md` | 24 | Agent-facing prose also follows the **create-skill** skill (Cursor's built-in for authori… | Agent-facing prose also follows the `skill-creator` skill for authoring SKILL.md files. |
| 06-cursor-neighbors | `skills/poteto-mode/SKILL.md` | 26 | - Before commit → the `deslop` skill from the `cursor-team-kit` plugin (`/deslop`). | - Before commit → the **unslop** skill over every comment, docstring, and commit message … |
| 06-cursor-neighbors | `skills/poteto-mode/SKILL.md` | 28 | - Shipping UI / IDE / CLI → the matching control skill. `cursor-team-kit` publishes `cont… | - Shipping UI / IDE / CLI → the project's verification skill, the `verify-<app>` skill th… |
| 06-cursor-neighbors | `skills/poteto-mode/SKILL.md` | 30 | → the **Babysit** playbook (`playbooks/babysit.md`), not Cursor's built-in babysit skill,… | → the **Babysit** playbook (`playbooks/babysit.md`). Never triggered |
| 06-cursor-neighbors | `skills/poteto-mode/SKILL.md` | 30 | ("babysit this", "get it green", "address the bugbot comments", and most often | ("babysit this", "get it green", "address the review comments", and most often |
| 06-cursor-neighbors | `skills/poteto-mode/SKILL.md` | 32 | - Bugbot or the agentic security review commented → skeptical posture. They catch real bu… | - A review bot or an agentic security review commented → skeptical posture. They catch re… |
| 06-cursor-neighbors | `skills/poteto-mode/SKILL.md` | 143 | then landing the contiguous verified run bottom-up through `gh` by default or Origin when… | then landing the contiguous verified run bottom-up through `gh`. |
| 06-cursor-neighbors | `skills/poteto-mode/SKILL.md` | 149 | going offline, a Cursor restart, or imminent context compaction. | going offline, a Claude Code restart, or imminent context compaction. |
| 06-cursor-neighbors | `skills/poteto-mode/playbooks/authoring-a-skill.md` | 5 | 1. Use the **create-skill** skill (Cursor's built-in for authoring SKILL.md files). | 1. Use the `skill-creator` skill for authoring SKILL.md files. |
| 06-cursor-neighbors | `skills/poteto-mode/playbooks/autonomous-run.md` | 6 | using Cursor's `/loop` command (a built-in, not a pstack skill) | using Claude Code's `/loop` command (a built-in, not a pstack skill) |
| 06-cursor-neighbors | `skills/poteto-mode/playbooks/bug-fix.md` | 8 | Drive a long or stubborn hunt with Cursor's `/loop` command. | Drive a long or stubborn hunt with Claude Code's `/loop` command. |
| 06-cursor-neighbors | `skills/poteto-mode/playbooks/opening-a-pr.md` | 9 | **PRs.** Run `/deslop` from `cursor-team-kit` over the diff before commit and `/no-commen… | **PRs.** Run `/unslop` over the diff's comments and messages before commit and `/no-comme… |
| 06-cursor-neighbors | `skills/poteto-mode/playbooks/multi-phase-plan.md` | 13 | Ten lanes at the PR head drive the real surface through its control skill, per the **swar… | Ten lanes at the PR head drive the real surface through its verification skill, per the *… |
| 06-cursor-neighbors | `skills/poteto-mode/playbooks/multi-phase-plan.md` | 15 | **Control skill.** Pick it by surface. Browser, Electron, and web UIs use `control-ui` fr… | **Verification skill.** Pick it by surface. Browser, Electron, and web UIs use the repo's… |
| 06-cursor-neighbors | `skills/poteto-mode/playbooks/multi-phase-plan.md` | 59 | - [ ] Run `/deslop` before each commit and `/no-comments` before review. / - [ ] Triage e… | - [ ] Run `/unslop` before each commit and `/no-comments` before review. / - [ ] Triage e… |
| 06-cursor-neighbors | `skills/poteto-mode/playbooks/multi-phase-plan.md` | 129 | - [ ] Bugbot triage done. | - [ ] Review-bot triage done. |
| 06-cursor-neighbors | `skills/poteto-mode/playbooks/babysit.md` | 3 | This playbook replaces Cursor's built-in babysit skill for these requests, so do not rout… | A request to land |
| 06-cursor-neighbors | `skills/poteto-mode/playbooks/babysit.md` | 7 | for "address the bugbot comments". | for "address the review comments". |
| 06-cursor-neighbors | `skills/poteto-mode/playbooks/babysit.md` | 7 | Undeclared defaults to `drive`. Small or docs-only PRs get `check`, not `drive`. GitHub C… | Undeclared defaults to `drive`. Small or docs-only PRs get `check`, not `drive`. Use the … |
| 06-cursor-neighbors | `skills/poteto-mode/playbooks/babysit.md` | 12 | 6. **Trust the active forge's verdict, not a green check list.** Ready means the forge ag… | 6. **Trust GitHub's merge state, not a green check list.** Ready means GitHub agrees the … |
| 06-cursor-neighbors | `skills/poteto-mode/playbooks/babysit.md` | 18 | 8. **Bugbot is triaged skeptically, always.** Verify each claim against the code per `../… | 8. **Review-bot comments are triaged skeptically, always.** Verify each claim against the… |
| 06-cursor-neighbors | `skills/poteto-mode/playbooks/babysit.md` | 18 | On Origin, reply with `origin pr thread reply <thread-id> <pr> --body-file <reply-file>`.… | Reply with `gh api |
| 06-cursor-neighbors | `skills/poteto-mode/playbooks/babysit.md` | 18 | On GitHub, use the watcher's Bugbot pass count. On Origin, derive the pass count from `or… | Count the bot's passes from the review history. From the third pass on, |
| 06-cursor-neighbors | `skills/poteto-mode/playbooks/babysit.md` | 19 | After GitHub reports `READY`, a queued `WAITING`/`merge-queue` stop, or `COMPLETE`, or af… | After the frontier is merge-ready, sweep the run's triage decisions once. Offer any team-… |
| 06-cursor-neighbors | `skills/poteto-mode/playbooks/shipping.md` | 7 | 1. **Resolve the forge, then verify every PR independently.** GitHub CLI (`gh`) is the de… | 1. **Verify every PR independently.** Use the GitHub CLI (`gh`). Never require Graphite (… |
| 06-cursor-neighbors | `skills/poteto-mode/playbooks/shipping.md` | 10 | with `origin pr edit <pr> --base <trunk>` or `gh pr edit <pr> --base <trunk>`. | with `gh pr edit <pr> --base <trunk>`. |
| 06-cursor-neighbors | `skills/poteto-mode/playbooks/shipping.md` | 11 | squash it with `origin pr merge <pr> --squash` or `gh pr merge <pr> --squash`. If require… | squash it with `gh pr merge <pr> --squash`. If requirements are still running and the use… |
| 06-cursor-neighbors | `skills/poteto-mode/playbooks/shipping.md` | 12 | 6. **Do not read GitHub `autoMergeRequest` as stack readiness.** At most it says GitHub a… | 6. **Do not read `autoMergeRequest` as stack readiness.** At most it says auto-merge was … |
| 06-cursor-neighbors | `skills/poteto-mode/playbooks/shipping.md` | 14 | With Origin, use `origin pr view <pr> --checks --comments` and `origin pr checks <pr> --w… | Use `gh pr checks <pr> --watch` only as an event wake and poll |
| 06-cursor-neighbors | `skills/poteto-mode/playbooks/shipping.md` | 14 | `BLOCKED` while checks are pending or auto-merge is armed is not failure. Do not use Baby… | `BLOCKED` while checks are pending or auto-merge is armed is not failure. Hold the watch |
| 06-cursor-neighbors | `skills/poteto-mode/playbooks/autopilot-full.md` | 6 | Resolve the forge once for the program. GitHub CLI (`gh`) is the default. If `command -v … | Use the GitHub CLI (`gh`). Never require Graphite (`gt`). One `pstack:poteto-agent` subag… |
| 06-cursor-neighbors | `skills/poteto-mode/playbooks/autopilot-full.md` | 6 | skeptical Bugbot triage per `../references/bugbot-triage.md`, a slop-strip (the `deslop` … | skeptical review-bot triage per `playbooks/babysit.md` step 8, a slop-strip (the **unslop… |
| 06-cursor-neighbors | `skills/poteto-mode/playbooks/autopilot-full.md` | 8 | (with the matching control skill, such as `control-cli` or `control-ui` from `cursor-team… | (with the project's verification skill, or a named driver where none exists) |
| 06-cursor-neighbors | `skills/poteto-mode/playbooks/autopilot-full.md` | 9 | The owner squash-merges its own PR through the resolved forge and returns. | The owner squash-merges its own PR with `gh pr merge <pr> --squash` and returns. |
| 06-cursor-neighbors | `skills/poteto-mode/playbooks/autopilot-full.md` | 10 | The root never gives or bypasses an approval that the forge enforces. | The root never gives or bypasses an approval that GitHub enforces. |
| 06-cursor-neighbors | `skills/poteto-mode/playbooks/autopilot-full.md` | 10 | On the operator's go, arm `/loop 1h` with a prompt that runs this tick. `/loop` works in … | On the operator's go, arm `/loop 1h` with a prompt that runs this tick. Never leave |
| 06-cursor-neighbors | `skills/poteto-mode/playbooks/autopilot-full.md` | 10 | re-read this playbook from trunk with `git show origin/main:pstack/skills/poteto-mode/pla… | re-read this playbook from `${CLAUDE_PLUGIN_ROOT}/skills/poteto-mode/playbooks/autopilot-… |
| 06-cursor-neighbors | `skills/poteto-mode/playbooks/autopilot-stack.md` | 5 | Resolve the forge once for the program. GitHub CLI (`gh`) is the default. If `command -v … | Use the GitHub CLI (`gh`). Never require Graphite (`gt`). One `pstack:poteto-agent` subag… |
| 06-cursor-neighbors | `skills/poteto-mode/playbooks/autopilot-stack.md` | 5 | skeptical Bugbot triage per `../references/bugbot-triage.md`, a slop-strip (the `deslop` … | skeptical review-bot triage per `playbooks/babysit.md` step 8, a slop-strip (the **unslop… |
| 06-cursor-neighbors | `skills/poteto-mode/playbooks/autopilot-stack.md` | 6 | re-read this playbook from trunk with `git show origin/main:pstack/skills/poteto-mode/pla… | re-read this playbook from `${CLAUDE_PLUGIN_ROOT}/skills/poteto-mode/playbooks/autopilot-… |
| 06-cursor-neighbors | `skills/poteto-mode/playbooks/autopilot-stack.md` | 10 | Create it with `origin pr create --status open --base <parent-branch>` or `gh pr create -… | Create it with `gh pr create --base <parent-branch>`. Retarget an existing PR with `gh pr… |
| 06-cursor-neighbors | `skills/poteto-mode/playbooks/autopilot-stack.md` | 12 | reviewable bottom-up in the resolved forge, | reviewable bottom-up on GitHub, |
| 06-cursor-neighbors | `skills/reflect/SKILL.md` | 54 | hand to Cursor's built-in `create-skill` skill and run its draft / test / iterate loop. | hand to the `skill-creator` skill and run its draft / test / iterate loop. |
| 06-cursor-neighbors | `skills/reflect/SKILL.md` | 55 | hand to `create-skill` and run its description-optimization loop. | hand to `skill-creator` and run its description-optimization loop. |
| 06-cursor-neighbors | `skills/reflect/SKILL.md` | 56 | - `new skill via create-skill: <kebab-name>`: hand creation to `create-skill`. Do not inv… | - `new skill via skill-creator: <kebab-name>`: hand creation to `skill-creator`. Do not i… |
| 06-cursor-neighbors | `skills/reflect/references/synthesizer.md` | 17 | propose `new skill via create-skill:` only when | propose `new skill via skill-creator:` only when |
| 06-cursor-neighbors | `skills/reflect/references/synthesizer.md` | 27 | - "Bugbot flagged regex backtracking on May 2" | - "The review bot flagged regex backtracking on May 2" |
| 06-cursor-neighbors | `skills/reflect/references/synthesizer.md` | 44 | \| <draft a new skill via create-skill> \| <new skill via create-skill: <kebab-name>> \| | \| <draft a new skill via skill-creator> \| <new skill via skill-creator: <kebab-name>> \| |
| 06-cursor-neighbors | `skills/automate-me/SKILL.md` | 3 | Drafts or revises a personal -mode skill via create-skill + unslop, | Drafts or revises a personal -mode skill via skill-creator + unslop, |
| 06-cursor-neighbors | `skills/automate-me/SKILL.md` | 11 | an inline mining pass (see step 1), Cursor's built-in `create-skill` (authoring), and the… | an inline mining pass (see step 1), the `skill-creator` skill (authoring), and the **unsl… |
| 06-cursor-neighbors | `skills/automate-me/SKILL.md` | 67 | Use Cursor's built-in `create-skill` skill to author the skill. | Use the `skill-creator` skill to author the skill. |
| 06-cursor-neighbors | `skills/automate-me/SKILL.md` | 72 | - Frontmatter formatting: follow `create-skill`'s YAML rules. | - Frontmatter formatting: follow `skill-creator`'s YAML rules. |
| 06-cursor-neighbors | `skills/automate-me/SKILL.md` | 77 | Apply the **unslop** skill and `create-skill`'s writing guidelines to every line. | Apply the **unslop** skill and `skill-creator`'s writing guidelines to every line. |
| 06-cursor-neighbors | `skills/automate-me/SKILL.md` | 96 | A `create-skill`-style test/iterate benchmark loop isn't useful here. | A `skill-creator`-style test/iterate benchmark loop isn't useful here. |
| 06-cursor-neighbors | `skills/automate-me/SKILL.md` | 102 | - User wants a task-specific skill (not working conventions): `create-skill` alone, no mi… | - User wants a task-specific skill (not working conventions): `skill-creator` alone, no m… |
| 07-cloud-playbooks | `skills/poteto-mode/playbooks/orchestrate.md` | 17 | - **Worker / verifier.** Always `environment: "cloud"` unless the task needs this machine… | - **Worker / verifier.** A background Agent tool subagent (`run_in_background: true`) in … |
| 07-cloud-playbooks | `skills/poteto-mode/playbooks/orchestrate.md` | 19 | Depth stays at coordinator, track, worker. Author the track decomposition per project (bu… | Depth stays at coordinator, track, worker. Author the track decomposition per project (bu… |
| 07-cloud-playbooks | `skills/poteto-mode/playbooks/orchestrate.md` | 25 | Create `orchestrate/<project-slug>/` in the current agent's store (path in the system pro… | Create `~/.claude/orchestrate/<project-slug>/`. Every file has exactly one writer. Owners… |
| 07-cloud-playbooks | `skills/poteto-mode/playbooks/orchestrate.md` | 48 | FORBIDDEN    no gt, no rebase, no force-push, | FORBIDDEN    no rebase, no force-push, |
| 07-cloud-playbooks | `skills/poteto-mode/playbooks/orchestrate.md` | 54 | Local spawns may reference the standing-orders file by store path. Verbatim paste is for … | A spawn may reference the standing-orders file by store path. Paste it verbatim into ever… |
| 07-cloud-playbooks | `skills/poteto-mode/playbooks/orchestrate.md` | 56 | its spawn budget with the cloud default and the local exception list, the drain protocol, | its spawn budget, the drain protocol, |
| 07-cloud-playbooks | `skills/poteto-mode/playbooks/orchestrate.md` | 63 | 2. **Install the runtime.** Run `orch init`. Open the trail via the show-me-your-work ski… | 2. **Install the runtime.** Create the store files listed above. Open the trail via the s… |
| 07-cloud-playbooks | `skills/poteto-mode/playbooks/orchestrate.md` | 72 | - On a completion notification, run `orch inbox push <agent> <unit> <status> [--report PA… | - On a completion notification, append one pointer file to `inbox/` (agent, unit, status,… |
| 07-cloud-playbooks | `skills/poteto-mode/playbooks/orchestrate.md` | 73 | Begin each batch with `orch inbox drain`. | Begin each batch by reading and clearing `inbox/`. |
| 07-cloud-playbooks | `skills/poteto-mode/playbooks/orchestrate.md` | 75 | writes the resulting rows through `orch unit add`, `orch unit set`, and `orch ledger reco… | writes the resulting rows into `units.tsv` and `ledger.tsv`, regenerates `status.md`, the… |
| 07-cloud-playbooks | `skills/poteto-mode/playbooks/orchestrate.md` | 77 | - A drain turn ends with the three lines from `orch status`: | - A drain turn ends with three lines from `status.md`: |
| 07-cloud-playbooks | `skills/poteto-mode/playbooks/orchestrate.md` | 81 | Recompute `frontier.json` from `gt` after every merge and stack mutation because GitHub b… | Recompute `frontier.json` from `gh pr list --json number,headRefName,baseRefName,headRefO… |
| 07-cloud-playbooks | `skills/poteto-mode/playbooks/orchestrate.md` | 82 | - Exactly one stacker per stack may run `gt`, serialized within its stack. Record the hol… | - Exactly one stacker per stack may rebase or retarget, serialized within its stack. Reco… |
| 07-cloud-playbooks | `skills/poteto-mode/playbooks/orchestrate.md` | 83 | - Workers never rebase and never run `gt`. | - Workers never rebase. |
| 07-cloud-playbooks | `skills/poteto-mode/playbooks/orchestrate.md` | 89 | A dedicated verifier agent (on a different model family than the worker) | A dedicated verifier agent (on a different model tier than the worker) |
| 07-cloud-playbooks | `skills/poteto-mode/playbooks/orchestrate.md` | 91 | Write ledger rows with `orch ledger record`. Check the current PR and head SHA with `orch… | `ledger.tsv` has one row per verdict, |
| 07-cloud-playbooks | `skills/poteto-mode/playbooks/orchestrate.md` | 93 | Work that exists only on one VM when that VM dies was never done. | Work that exists only in one worktree when its agent dies was never done. |
| 07-cloud-playbooks | `skills/poteto-mode/playbooks/orchestrate.md` | 97 | Probe read-only: the ledger, `units.tsv`, `gh`, pushed branches, the cloud agent's status… | Probe read-only: the ledger, `units.tsv`, `gh`, pushed branches. |
| 07-cloud-playbooks | `skills/poteto-mode/playbooks/orchestrate.md` | 103 | - After a Cursor restart: local agents are dead, cloud work is not. Re-read the standing … | - After a Claude Code restart: background subagents are dead, pushed branches and open PR… |
| 07-cloud-playbooks | `skills/poteto-mode/playbooks/autopilot-full.md` | 13 | **Reply:** the queue with each PR's owner, | For a queue of independent units without the per-PR owner lifecycle, the claudefiles `spa… |
| 07-cloud-playbooks | `skills/poteto-mode/playbooks/autopilot-stack.md` | 14 | **Choosing between the autopilots.** | For a queue of independent units without the per-PR owner lifecycle, the claudefiles `spa… |
| 07-cloud-playbooks | `skills/poteto-mode/playbooks/multi-phase-plan.md` | 71 | Each live lane runs on its own cloud VM at the PR head. Drive through `control-ui` or `co… | Each live lane runs in its own git worktree at the PR head. Drive through the project's v… |
| 07-cloud-playbooks | `skills/swarm/SKILL.md` | 9 | Fan out N parallel cloud workers. | Fan out N parallel background workers. |
| 07-cloud-playbooks | `skills/swarm/SKILL.md` | 24 | N is total workers, not the cloud concurrency limit. | N is total workers, not a concurrency limit. |
| 07-cloud-playbooks | `skills/swarm/SKILL.md` | 36 | If a worker drops out, proceed with N-1 and note it. | If a worker drops out, proceed with N-1 and note it. /  / For fan-out that also plans the… |
| 07-cloud-playbooks | `skills/poteto-help/SKILL.md` | 74 | \| Run parallel checks over slices, or race workers, as cloud agents \| | \| Run parallel checks over slices, or race workers, as background subagents \| |
| 08-poteto-help | `skills/poteto-help/SKILL.md` | 11 | do the work under it, and mention once that a Custom Mode keeps it on. | do the work under it, and mention once that starting each task with it keeps the style on. |
| 08-poteto-help | `skills/poteto-help/SKILL.md` | 13 | The links here point into the installed plugin, which the user may not be able to open, s… | The links here point into the installed plugin, so give the user the file's absolute path… |
| 08-poteto-help | `skills/poteto-help/SKILL.md` | 27 | - No `~/.cursor/rules/pstack-models.mdc` means `/setup-pstack` hasn't run for this user, … | (removed) |
| 08-poteto-help | `skills/poteto-help/SKILL.md` | 29 | When the model rule is missing and it matters, ask whether the user wants to pick a model… | (removed) |
| 08-poteto-help | `skills/poteto-help/SKILL.md` | 31 | 1. Install with `/add-plugin pstack` in chat, or from Customize in the sidebar. / 2. Run … | 1. pstack ships as the `pstack` plugin in the claudefiles marketplace. `/setup` in the cl… |
| 08-poteto-help | `skills/poteto-help/SKILL.md` | 43 | Read [`references/prompting.md`](references/prompting.md) before you help word one. [Guid… | Read [`references/prompting.md`](references/prompting.md) before you help word one. /  / … |
| 08-poteto-help | `skills/poteto-help/SKILL.md` | 75 | \| Pick a model for each role and a reasoning budget \| [`/setup-pstack`](../setup-pstack… | (removed) |
| 08-poteto-help | `skills/poteto-help/SKILL.md` | 78 | \| Build a page whose buttons wake a Grok Bot over a webhook \| [`/make-bot-ui`](../make-… | (removed) |
| 08-poteto-help | `skills/poteto-help/SKILL.md` | 93 | - `/deslop`, `control-cli`, and `control-ui` ship in the `cursor-team-kit` plugin. / - `/… | - `/loop` is a Claude Code built-in. `skill-creator` and `agent-browser` are claudefiles … |
| 08-poteto-help | `skills/poteto-help/SKILL.md` | 108 | Without `/poteto-mode`, a phrase such as "babysit this pr" can start Cursor's own skill f… | The Playbooks section of [`poteto-mode`](../poteto-mode/SKILL.md) lists every playbook an… |
| 08-poteto-help | `skills/poteto-help/SKILL.md` | 110 | pstack has no planning skill. Cursor's Plan Mode works alongside it. | pstack has no planning skill. Claude Code's plan mode works alongside it. |
| 08-poteto-help | `skills/poteto-help/SKILL.md` | 112 | Typing `/principle-<name>` still loads one on demand. [Guide page 8](../../docs/guide/08-… | Typing `/pstack:principle-<name>` still loads one on demand. The Principles section of [`… |
| 08-poteto-help | `skills/poteto-help/SKILL.md` | 118 | \| The mode stopped applying after a few turns \| It was started with Enter. Start it as … | \| The mode stopped applying after a few turns \| Start each task with `/pstack:poteto-mo… |
| 08-poteto-help | `skills/poteto-help/SKILL.md` | 120 | \| A new model choice had no effect \| The rule from `/setup-pstack` applies to new chats… | (removed) |
| 08-poteto-help | `skills/poteto-help/SKILL.md` | 121 | \| A skill didn't load on its own \| Only `/setup-pstack` loads from the user's words. Th… | \| A skill didn't load on its own \| Skills load when the user types them or when `/potet… |
| 08-poteto-help | `skills/poteto-help/SKILL.md` | 122 | \| Parallel agents overwrote each other \| Give each agent its own worktree, or run them … | \| Parallel agents overwrote each other \| Give each agent its own worktree, `isolation: … |
| 08-poteto-help | `skills/poteto-help/SKILL.md` | 123 | \| An overnight run moved but finished nothing \| `/loop` needs a check that can pass or … | \| An overnight run moved but finished nothing \| `/loop` needs a check that can pass or … |
| 08-poteto-help | `skills/poteto-help/SKILL.md` | 126 | For a run that drifts, [`references/prompting.md`](references/prompting.md) has one-line … | For a run that drifts, [`references/prompting.md`](references/prompting.md) has one-line … |
| 08-poteto-help | `skills/poteto-help/SKILL.md` | 133 | - Fix a misbehaving skill in its own PR, not inside the feature work where it went wrong.… | - Fix a misbehaving skill in its own PR, not inside the feature work where it went wrong. |
| 09-wording | `skills/poteto-help/SKILL.md` | 39 | This is a port of pstack from the Cursor plugins repository. Skills refer | This is a port of pstack by Lauren Tan (the plugin's `README.md` names the upstream). Ski… |
| 09-wording | `skills/why/SKILL.md` | 94 | if the user's `why` question is a precursor to changing this code, | if the user's `why` question is a prelude to changing this code, |
| 09-wording | `skills/poteto-mode/SKILL.md` | 148 | from a transcript, cloud-agent URL, or pushed branch. | from a transcript or pushed branch. |

## Re-vendor

1. Clone the upstream at the new commit: `git clone --depth 1 https://github.com/cursor/plugins /tmp/cursor-plugins && git -C /tmp/cursor-plugins log -1 --format=%H`.
2. Copy `pstack/` into a scratch dir with the cuts above applied (the Cut table is the list; copy the kept paths one by one rather than copying everything and deleting).
3. Reapply the patches in order: `git apply --directory=plugins/pstack patches/*.patch`. A patch that fails to apply means the upstream line changed; reread the upstream file, redo that patch by hand, and regenerate it with `git diff` against the fresh copy.
4. Diff the result against the current tree (`git diff --stat`) and reread every hunk that touches a `model:`, `subagent_type`, or path. Rerun the verification grep from the port commit message.
5. Update the Commit, Date, and Version rows above and bump the `-claude.N` suffix in `.claude-plugin/plugin.json`.
