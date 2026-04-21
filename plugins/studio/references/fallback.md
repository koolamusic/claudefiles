# Studio Fallback — Windows / Container Environments

Studio's default behaviour creates filesystem symlinks at the project root pointing into `~/.studio/<slug>/`. On hosts where those symlinks can't be created, use the fallback described here: configure `additionalDirectories` in `.claude/settings.local.json`, and register the session-start hook with an absolute path in the same file.

## When to use this

- Native Windows without admin / Developer Mode (directory symlinks require elevation).
- Docker containers where `~/.studio/` is not bind-mounted into the container.
- Any host filesystem that rejects symlinks.
- Explicit preference to avoid host-level symlinks (e.g. sandboxed CI).
- *Not* needed for macOS, Linux, or WSL2 (with `~/.studio/` inside the Linux home). Those platforms should use `/studio:setup` as designed.

## What changes vs normal mode

| Concern | Normal mode | Fallback mode |
|---|---|---|
| State access | Symlinks at project root (`.planning`, `.jira`, `.retrospective`, `.uat`) | `additionalDirectories` in `.claude/settings.local.json` pointing at `~/.studio/<slug>/` |
| Shell discoverability | `ls .planning/` works from any shell in the project root | Does NOT work — only Claude Code's tools see the workspace paths |
| Session-start hook | Wired via workspace's `settings.json` (reached through the symlinked `.claude/` if present, or via the project's own `settings.json`) | Registered with an absolute path in the project's `.claude/settings.local.json` |
| `.workspacerc` | Written at project root (gitignored via studio-managed block — machine-local) | Same — still written, same format, still gitignored |

## Setup steps

1. Clone `~/.studio/` as usual:

   ```bash
   git clone <studio-repo> ~/.studio
   ```

2. Create the workspace directory manually (matching what `/studio:setup` would create — see `plugins/studio/templates/studio.yaml` for the exact subdir list):

   ```bash
   mkdir -p ~/.studio/<slug>/{planning,retrospective,uat,jira,memory,memory/archive,skills,hooks}
   ```

3. Copy the session-start hook into the workspace:

   ```bash
   cp <CLAUDE_PLUGIN_ROOT>/hooks/session-start.sh ~/.studio/<slug>/hooks/session-start.sh
   chmod +x ~/.studio/<slug>/hooks/session-start.sh
   ```

4. Write `.workspacerc` at the project root with:

   ```json
   {"version": 1, "workspace": "~/.studio/<slug>"}
   ```

   This file is machine-local and must be gitignored via the studio-managed block (step 6 handles that). Different machines may store the workspace at different absolute paths — committing `.workspacerc` would leak a machine-specific value.

5. Create or edit `.claude/settings.local.json` at the project root with the snippet from [§ Exact settings.local.json](#exact-settingslocaljson) below.

6. Ensure `.workspacerc` is listed in the project's studio-managed `.gitignore` block. The default `studio.yaml` ships `.workspacerc` as a managed-block entry, so applying the block covers this automatically. If you don't have a studio-managed block yet, paste the following between `# >>> studio (managed) >>>` and `# <<< studio (managed) <<<` markers in `.gitignore`:

   ```
   .jira
   .planning
   .retrospective
   .uat
   .studio
   .workspacerc
   ```

7. Restart Claude Code for the `settings.local.json` changes to take effect.

## Exact settings.local.json

Paste this into `.claude/settings.local.json` at your project root. If the file already exists, merge the `additionalDirectories` and `hooks` keys with your existing content.

```json
{
  "additionalDirectories": [
    "~/.studio/<slug>/"
  ],
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup",
        "hooks": [
          {
            "type": "command",
            "command": "$HOME/.studio/<slug>/hooks/session-start.sh",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

- Replace `<slug>` with your workspace slug (typically the repo basename).
- `$HOME` expansion: Claude Code's hook runner expands `$HOME` at runtime. On native Windows cmd this is the user profile path — confirm with `echo %USERPROFILE%` and hard-code the absolute path if shell expansion is unreliable on your shell.

## Why the hook is registered here (not in the workspace)

Claude Code does not load hook entries from `settings.json` files inside directories added via `additionalDirectories`. The official settings docs describe the field as granting *"additional working directories for file access"* and note that *"most `.claude/` configuration is not discovered from these directories"* — i.e. the added directory extends tool-access scope (Read, Write, and Bash tools can see paths under it) but does NOT extend configuration scope. Hooks are loaded only from:

- `~/.claude/settings.json` (user-level, machine-local)
- the project's own `.claude/settings.json` (committed, shared)
- the project's own `.claude/settings.local.json` (gitignored, machine-local)
- managed policy settings and plugin / skill / agent bundled hooks

The project's own `.claude/settings.local.json` is therefore the natural place to register the studio session-start hook under fallback — the hook script still lives in the workspace (`~/.studio/<slug>/hooks/session-start.sh`), but its registration points at that absolute path rather than relying on the `.claude/` tree inside the workspace being discovered.

See Claude Code docs on hooks and settings precedence — re-verify against live docs at time of use if the Claude Code version advances substantially; this note may need updating as Claude Code evolves.

## What you lose

- Shell `ls .planning/` no longer works in fallback — use `ls ~/.studio/<slug>/planning/` directly.
- Some tools that follow symlinks at the filesystem level (editors, build tools, language servers) will not see the workspace paths — they only see the project root.
- Workspace paths appear as absolute (`~/.studio/<slug>/...`) in Claude's tool calls rather than as project-relative (`.planning/...`). Skills and commands that hard-code relative paths like `.planning/` will silently fail to find state unless they're updated to read `.workspacerc` and resolve against the workspace path.

## Limitations and caveats

- `.claude/settings.local.json` is gitignored by default in Claude Code's own gitignore recommendations. That is correct here — the absolute path is user-specific and should not be committed. Each collaborator configures their own fallback if needed.
- If multiple users on the same project use different fallback paths (`~/.studio/<slug>/` on one machine vs `C:\Users\...\studio\<slug>\` on another), each keeps their own uncommitted `settings.local.json`.
- Migrating between fallback and normal mode: delete `settings.local.json`'s `additionalDirectories` and `hooks.SessionStart` entries, then run `/studio:setup` to create the symlinks. `.workspacerc` stays as-is.

---

Last verified against Claude Code docs: 2026-04-19.
