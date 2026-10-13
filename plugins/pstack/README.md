# pstack

Rigorous agent workflows: go deep first, write less code, verify it. `/pstack:poteto-mode` matches a task to a playbook (feature, bug fix, refactoring, investigation, perf, hillclimb, multi-phase plan, and more), copies the playbook's steps into the todo list, and routes through the bundled skills as the steps need them: `how` and `why` to understand code, `architect` and `arena` for design, `swarm` for fan-out, `interrogate` for adversarial review, `unslop` and `technical-writing` for prose, and 24 one-rule `principle-*` skills it cites in its replies.

This is a port of [pstack](https://github.com/cursor/plugins/tree/main/pstack) from github.com/cursor/plugins by Lauren Tan, taken at commit `1dcc2ba` (v0.15.21), patched to run on Claude Code. MIT, see `LICENSE`.

Cut: the Cursor-only pieces (`setup-pstack` and its model rule, `make-bot-ui`, the `benny` automation, the orchestration and PR-watch scripts, docs and assets). Everything that depended on a Cursor neighbor (`cursor-team-kit`, Bugbot, Origin, cloud agents) was rewritten for Claude Code's Agent tool, `gh`, and the local `spawn` and `orchestrator` skills.

## Invoke

Installed by `/setup` through the claudefiles marketplace, or by hand with `/plugin install pstack --marketplace koolamusic/claudefiles`.

- `/pstack:poteto-mode <task>` runs the playbook for the task. Start each new task with it.
- `/pstack:poteto-help <question>` explains the skills, playbooks, and principles and hands you a prompt.
- Any bundled skill by name, for example `/pstack:how`, `/pstack:why`, `/pstack:interrogate`, `/pstack:unslop`.
- Subagents spawned inside a playbook step use `subagent_type: "pstack:poteto-agent"`; `/pstack:no-comments` spawns `pstack:comment-sicko`.

## Models

Upstream let `/setup-pstack` map a model to each role. This port fixes the table. The Agent tool accepts `sonnet`, `opus`, `haiku`, and `fable`; omitting `model` inherits the chat model.

| Role | `model` |
|---|---|
| feature and refactoring, bug-fix, perf-issue, hillclimb, how explorer, why investigators, reflect tooling, swarm workers | `sonnet` |
| judgment and prose, how explainer, why synthesizer, reflect judgment, divergent, synthesizer | inherit the parent (omit `model`) |
| hardest tasks | `fable` |
| arena runners, arena cross-judge pool, architect runners, interrogate reviewers | `opus` and `sonnet`, one subagent per entry |

Source, cut list, patch log, and the re-vendor procedure are in [UPSTREAM.md](UPSTREAM.md).
