# Author conventions

Issues and PRs are public artifacts. Write them for an external reader who has no access to `.jira/`, the sprint handoff, or any internal context. This governs both `/jira:issue` (issue bodies) and `/jira:execute` (PR bodies).

It restates the global "author for an external reader" stance — so the rule holds even when this plugin is installed without that global file — then adds the jira-specific layer.

## Audience & framing

- Write for an external reader with no access to `.jira/` or the handoff.
- Focus on the WHAT and why it matters, not the how. State the outcome — the change in capability or contract.
- Keep internal mechanics (file moves, design splits, refactor steps) in `.jira/`, not the artifact.

## No internal jargon in the body

- No internal acronyms or names. Say it in plain English ("the background token cache", "permission checks", "the authentication package boundary") or leave it out.
- A locked decision appears as a stated constraint or acceptance criterion — never as an internal decision ID.

## Structure

- Milestone = Epic; each sprint = a Feature (FEAT-…). Keep it succinct.

## Forbidden in issue/PR bodies

- Decision IDs
- `.jira/` filenames and paths
- Sprint slugs and wave labels
- Worktree / branch internals
- The AI-attribution trailer

## Linking

- Feature PRs only link issues: `Refs #NN`, no `Closes`.
- The canary→main promotion PR carries the `Closes` keywords — auto-close fires only on main.
