---
description: Build a static HTML review site from all sprints in .jira/sprints/ and serve it on a local port. Default serves every markdown file in every sprint; filter with --only. Extra markdown dirs (RFCs, specs) can be appended as sections with --include.
allowed-tools: Bash, Read, Glob
argument-hint: [--port <8081>] [--only BRIEF,RESEARCH,CONTEXT,CHECK] [--include <dir>[:Title]] [--title <site title>]
---

Serve the sprint corpus as a browsable review site: sidebar of sprints (collapsible, docs in read order, APPROVE/REVISE badges parsed from each CHECK.md), a STATE page when `.jira/STATE.md` exists, and optional extra sections for any markdown directory.

## Steps

1. **Parse flags** from the arguments: `--port` (default `8081`), `--only` (comma list of doc names without `.md` — default is ALL markdown files per sprint), `--include <dir>[:Title]` (repeatable — appends a markdown directory as a named section; e.g. `--include .project/rfc.one:RFCs`), `--title` (site title, defaults to `<repo-basename> · Sprint Review`).

2. **Build.** From the repo root run:

   ```bash
   node ${CLAUDE_PLUGIN_ROOT}/scripts/serve-site.mjs --root "$(git rev-parse --show-toplevel)" [pass-through flags]
   ```

   The script resolves a GFM renderer from the host project's own `node_modules` (micromark+gfm, marked, or markdown-it — direct or via the pnpm store) and falls back to a built-in mini renderer when none exists. Output goes to `/tmp/jira-serve/<repo-basename>/` (override with `--out`). It never writes inside the repo.

3. **Serve.** If the port is free, start a static server in the background:

   ```bash
   python3 -m http.server <port> --directory /tmp/jira-serve/<repo-basename> --bind 0.0.0.0
   ```

   (Fallback when python3 is absent: `npx -y serve -l <port> /tmp/jira-serve/<repo-basename>`.) If the port is already serving a previous run of this command, just rebuild — the server picks up the new files on refresh. If the port is held by something else, report it and pick the next free port.

4. **Report** the URL(s) — `http://localhost:<port>` plus the machine's LAN address when available — the page count, what was included/filtered, and the one-line rebuild command for mid-review refreshes.

## Rules

- Read-only with respect to the repository: the site is built OUTSIDE the repo; never add build output or server artifacts to git.
- Re-running rebuilds from scratch (the out dir is wiped first) — safe to run after every doc change.
- The server is a convenience for review, not a deployment: bind-all is fine on trusted networks; mention `ssh -L` tunneling for anything else.
- Sprints are ordered most-recently-modified first; docs within a sprint follow read order (BRIEF, RESEARCH, CONTEXT, numbered plans, CHECK, ISSUE-DRAFT, then the rest).
