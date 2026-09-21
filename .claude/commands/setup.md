---
name: setup
allowed-tools: Bash(cp:*), Bash(mkdir:*), Bash(ls:*), Bash(cat:*), Bash(mv:*), Bash(rm:*), Bash(date:*), Bash(uname:*), Bash(chmod:*), Bash(npx:*), Bash(command:*), Read, Write, Glob
description: Install claudefiles — copy skills, commands, sounds, hooks, and plugins into ~/.claude/
---

## Your task

Install claudefiles by reading the manifest and deploying everything to the target directory.

### Step 1: Read the manifest

Read `claudefiles.yaml` in this repo root. It declares what gets installed and how.

### Step 2: Ask install target

Ask the user:
- **Global** (recommended): Install to `~/.claude/` — available in all Claude Code sessions
- **Local**: Install to `./.claude/` in the current project only

### Step 3: Detect platform

Determine if running on macOS or Linux to resolve the `{{sound_player}}` template variable:
- macOS → `afplay`
- Linux → `aplay`

```bash
uname -s
```

### Step 4: Create target directories

```bash
mkdir -p <target>/skills
mkdir -p <target>/commands
mkdir -p <target>/sounds
mkdir -p <target>/hooks
```

### Step 5: Copy files

Copy the contents declared in `install.targets`.

Skills come with one exception: any skill directory named in an experimental feature's `skills:` list (e.g. `tower`) is opt-in and is copied in Step 8.5 only if the user enables that feature. Collect those names from the manifest first, then copy everything else:

```bash
# Skills — copy each skill directory, skipping opt-in skills declared under
# experimental.features[].skills (space-separated; taken from the manifest)
OPT_IN_SKILLS="<experimental.features[].skills, space-separated>"
for src in skills/*/; do
  name=$(basename "$src")
  case " $OPT_IN_SKILLS " in *" $name "*) continue ;; esac
  cp -R "$src" <target>/skills/
done

# Commands — copy all .md files
cp commands/*.md <target>/commands/

# Sounds — copy all files
cp sounds/* <target>/sounds/

# Hooks — copy all hook scripts and make executable
cp hooks/* <target>/hooks/
chmod +x <target>/hooks/*
```

### Step 6: Deploy nvim plugin overlays (skip per-file if exists)

Overlay `dotfiles/nvim/lua/plugins/` onto `~/.config/nvim/lua/plugins/`. The `nvim_plugins` target in the manifest has `skip_if_exists: true` at the file level — never overwrite an existing plugin file the user already customized.

```bash
mkdir -p ~/.config/nvim/lua/plugins
for src in dotfiles/nvim/lua/plugins/*; do
  name=$(basename "$src")
  dest="$HOME/.config/nvim/lua/plugins/$name"
  if [ -e "$dest" ]; then
    echo "nvim plugin $name already exists — skipping"
  else
    cp "$src" "$dest"
    echo "nvim plugin $name installed"
  fi
done
```

Record per-file outcomes for the summary.

### Step 7: Smart-merge global CLAUDE.md

Deploy the global agent directives to `<target>/CLAUDE.md` using a smart-merge strategy:

1. Read `dotfiles/CLAUDE.md` from this repo (the source directives)
2. If `<target>/CLAUDE.md` already exists and is non-empty:
   a. Back it up: `cp <target>/CLAUDE.md <target>/CLAUDE.md.backup`
   b. Read the existing CLAUDE.md
   c. **Smart-merge**: Compare by section header (## headings). For each section in the source:
      - If the section doesn't exist in the target → append it
      - If the section exists in the target → keep the target's version (user customizations win)
   d. Preserve any sections in the target that don't exist in the source (user's custom sections)
3. If `<target>/CLAUDE.md` doesn't exist or is empty, copy the source as-is

This ensures user customizations are preserved while new guardrails from upstream are added.

### Step 7.5: Smart-merge keybindings.json

Deploy custom keybindings to `<target>/keybindings.json` from `dotfiles/keybindings.json`. These are **additive overrides** — Claude Code appends them after its built-in defaults, so the file only needs to contain the bindings being changed.

1. Read `dotfiles/keybindings.json` from this repo (the source bindings).
2. If `<target>/keybindings.json` already exists and is non-empty:
   a. Back it up: `cp <target>/keybindings.json <target>/keybindings.json.backup`
   b. Read the existing file.
   c. **Merge by context**: each entry in `bindings[]` has a `context` (e.g. `Scroll`, `Chat`). For each context block in the source, merge its `bindings` object into the matching target context (key-by-key). On a per-key conflict, **the source (repo) value wins** — keybindings are intentional config the repo is the source of truth for. Preserve any contexts/keys in the target that don't exist in the source (user's own additions).
3. If `<target>/keybindings.json` doesn't exist or is empty, copy the source as-is.

Always keep the `$schema` and `$docs` top-level fields.

### Step 8: Smart-merge settings.json

If `<target>/settings.json` already exists:
1. Back it up: `cp <target>/settings.json <target>/settings.json.backup`
2. Read the existing settings
3. Deep-merge: repo settings take priority, but preserve user's custom keys that don't conflict

If no existing settings.json, create a fresh one.

Generate the final `settings.json` from the manifest's `settings` section:
- Resolve `{{sound_player}}` with the platform-appropriate player
- **Shell compatibility**: Claude Code hooks execute via `/bin/sh` (POSIX shell), not bash. Any hook command that uses bash-specific syntax (arrays `()`, `$RANDOM`, `${#array[@]}`, `[[ ]]`) MUST be wrapped in `bash -c '...'`. Scan every resolved command string before writing it to settings.json.
- Structure hooks in the Claude Code settings.json format:
  ```json
  {
    "hooks": {
      "SessionStart": [{ "matcher": "...", "hooks": [{ "type": "command", "command": "..." }] }],
      ...
    },
    "enabledPlugins": { "<plugin>": true, ... },
    "alwaysThinkingEnabled": true
  }
  ```
- **All plugins** from the manifest's `settings.plugins` list must appear in `enabledPlugins` set to `true` — this includes both marketplace plugins (`feature-dev@claude-plugins-official`) and local plugins (`ux@claudefiles`, `jira@claudefiles`).
- Include `extraKnownMarketplaces` from the manifest so Claude Code can discover the `claudefiles` marketplace on future sessions.

Write the merged settings to `<target>/settings.json`.

### Step 8.5: Prompt for experimental features

Check the manifest for an `experimental.features` list. If present and non-empty, ask the user which (if any) to enable. Experimental features are **off by default**. Some enable hook entries (e.g. `trust-monitor`); some enable plugins that ship commands and agents; some install a skill that is otherwise skipped (e.g. `tower`). Hook scripts are still copied by Step 5; opting in wires them into `settings.json`, activates a plugin, or copies the skill. You can toggle features later by editing `settings.json` or re-running `/setup`.

Use `AskUserQuestion` with `multiSelect: true` — one option per feature, labeled by `name`, described by the `description` field from the manifest. Include the preamble above so users understand some features install plugins or skills, not just hook entries.

For each feature the user opts into, apply the feature's declared effects. A feature may declare `settings:`, `enablePlugin:`, `skills:`, `requires:`, several of these, or none:

0. **If the feature has a `requires:` list**, check it before anything else. Print the prerequisite so the user sees what the feature assumes, then look each `command:` up on PATH:
   ```bash
   command -v herdr
   ```
   A non-zero exit status means the command is missing. If any command is missing, say so, point at its `install:` value (for `tower`: Herdr, https://herdr.dev), and **skip the feature entirely** — do not copy its skills, merge its settings, or enable its plugin. Record it as skipped for the summary. If everything is present, continue with the actions below.

1. **If the feature has a `settings:` fragment**: **Deep-merge** that fragment into the settings.json being written — same strategy as Step 8. For array-valued keys like `hooks.PostToolUse`, **array-append** (don't replace).
2. **If the feature has an `enablePlugin:` key** (string plugin name, e.g. `<plugin>@claudefiles`): add the named plugin to the `enabledPlugins` object in the target `settings.json`, setting its value to `true`. **No-op guard**: if the plugin is already enabled (e.g. it appears under the manifest's top-level `settings.plugins:` list and was therefore already written in Step 8), adding it again is a harmless no-op — do not error.
3. **If the feature has a `skills:` list**: copy each named skill directory now — it was deliberately skipped in Step 5:
   ```bash
   cp -R skills/tower <target>/skills/
   ```
4. **If the feature declares several keys**: run each action independently (e.g. deep-merge the settings fragment AND add the plugin to `enabledPlugins`). No cross-interference.
5. **If the feature has none of these keys**: record the feature name for the summary but do not mutate `settings.json`. This is a legal shape (useful for documentation-only experimental flags).
6. In all cases, record the enabled feature name (and, if `enablePlugin` was set, the plugin name; if `skills:` was set, the skill names) for the final summary in Step 11.

If the user opts into none (or the list is empty), proceed with base settings only. Do NOT prompt if `experimental.features` is absent or `[]`.

Users can enable later by hand: copy the relevant `settings:` fragment from `claudefiles.yaml` into their `~/.claude/settings.json` (or project-local `.claude/settings.json`), set `"enabledPlugins": { "<plugin>": true }` for an `enablePlugin:` feature, or `cp -R skills/<name> ~/.claude/skills/` for a `skills:` feature, and restart Claude Code.

### Step 9: Set required environment variables

Read the `env` section from `claudefiles.yaml`. For each variable declared:

1. Detect the user's shell rc file:
   - zsh → `~/.zshrc`
   - bash → `~/.bashrc`
2. Check if `export <VAR>=` already exists in the rc file
3. If missing, append `export <VAR>="<value>"` to the rc file
4. If present but with a different value, update it to match the manifest

```bash
# Example for MY_VAR=value
grep -q 'export MY_VAR=' ~/.zshrc || echo 'export MY_VAR="value"' >> ~/.zshrc
```

### Step 10: Install external dependencies

Install GSD (get-shit-done) — a spec-driven development system for Claude Code.

Determine the install flag based on the user's target choice:
- **Global** → `--global`
- **Local** → `--local`

```bash
npx get-shit-done-cc@latest --claude --global  # or --local
```

If the install fails, warn the user but continue — GSD is optional and can be installed separately later.

### Step 11: Print summary

List what was installed:
- Number of skills copied
- Number of commands copied
- Number of sound files copied
- Number of hooks copied
- Settings merged (or created fresh)
- Nvim config (installed or skipped — existing config preserved)
- Global CLAUDE.md deployed (merged, created fresh, or unchanged)
- Keybindings deployed (merged, created fresh, or unchanged)
- Whether a backup was made
- The target directory
- Plugins enabled via `enabledPlugins` and `extraKnownMarketplaces` (list each)
- Experimental features enabled (list each, or "none" if user declined). For each opted-in feature, show `<name>`; if the feature declared `enablePlugin:`, annotate with `(plugin: <plugin-name>)`; if it declared `skills:`, annotate with `(skill: <name>)`. Example lines: `- trust-monitor`, `- tower (skill: tower)`.
- Experimental features skipped because a prerequisite was missing (e.g. `- tower — herdr not on PATH, see https://herdr.dev`), or omit the line if none.
- GSD install status (success or skipped)
- Environment variables set (or already present)

**Remind the user**: Restart Claude Code for plugins and settings to take effect. Claude Code will auto-install plugins from the `claudefiles` marketplace on next startup. Once restarted:

- **`/jira:init`** in any git repo bootstraps a sprint workspace (`.jira/` with `STATE.md`, `sprints/`, `.gitignore`). This is the primary workflow.
- **`/gsd:help`** still works if you want the legacy GSD commands — kept available but no longer the default path.
- **`/help`** lists everything currently registered.
