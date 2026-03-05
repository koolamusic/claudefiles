# CLAUDE.md

This is a Claude Code configuration repository. It is opinionated toward Claude Code and does not target other AI coding assistants.

## What this repo is

Portable configuration for Claude Code — skills, commands, hooks, sounds, and settings deployed to `~/.claude/`. Think dotfiles, but for Claude.

## Architecture

`claudefiles.yaml` is the source of truth. It declares install targets, settings to merge, and platform-specific values. The `/setup` command reads this manifest and does the deployment. No imperative installer scripts beyond bootstrap.

### Setup command

`/setup` is a **project-level command** (`.claude/commands/setup.md`). It only works when Claude is running inside this repo. This solves the bootstrap chicken-and-egg: the command is available immediately after cloning, before anything is deployed globally.

### Install targets

| Target | Directory | Deployed to |
|--------|-----------|-------------|
| skills | `skills/` | `~/.claude/skills/` |
| commands | `commands/` | `~/.claude/commands/` |
| sounds | `sounds/` | `~/.claude/sounds/` |
| hooks | `hooks/` | `~/.claude/hooks/` |
| plugins | `plugins/` | `~/.claude/plugins/cache/claudefiles/<name>/local/` |

Note: `commands/` contains only global commands (`/gcw`, `/gitconfig`). `/setup` lives in `.claude/commands/` as a project-level command and is not deployed globally.

### Plugins

Local plugins in `plugins/` are deployed as `<name>@claudefiles`. Each plugin directory must contain `.claude-plugin/plugin.json`. Setup copies files to the plugin cache, registers them in `installed_plugins.json`, and enables them in `settings.json`. Requires a session restart to take effect.

Git configuration (`dotfiles/`) is installed separately via `/gitconfig`.

### Settings merge

`settings.json` is a reference file showing the final structure. The manifest's `settings` section uses template variables (`{{sound_player}}`) resolved at install time based on platform detection.

## Conventions

- Every skill has a `SKILL.md` with YAML frontmatter (`name`, `description`)
- Every command has a `.md` with YAML frontmatter (`name`, `allowed-tools`, `description`)
- Every hook script has a YAML-style documentation header in comments
- Large skills use `references/` subdirectories for progressive disclosure — keep the entry SKILL.md lean
- Sounds are `.wav` files in `sounds/`

## Not in scope (yet)

**Claudefiles spec** — a formal specification for the `claudefiles.yaml` manifest format (schema, validation, versioning, cross-repo compatibility). This would allow other people to create their own claudefiles repos with interoperable structure. Not tackling this yet, but it's a natural next step.

## Development

`.resource/` contains source materials (upstream repos, reference files). It is gitignored and not deployed. When adding content from `.resource/`, copy and adapt — don't symlink.
