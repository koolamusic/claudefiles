---
name: setup
allowed-tools: Bash(cp:*), Bash(mkdir:*), Bash(ls:*), Bash(cat:*), Bash(mv:*), Bash(rm:*), Read, Write, Glob
description: Install claudefiles — copy skills, commands, sounds, and merge settings into ~/.claude/
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

Copy the contents declared in `install.targets`:

```bash
# Skills — copy each skill directory
cp -R skills/* <target>/skills/

# Commands — copy all .md files
cp commands/*.md <target>/commands/

# Sounds — copy all files
cp sounds/* <target>/sounds/

# Hooks — copy all hook scripts and make executable
cp hooks/* <target>/hooks/
chmod +x <target>/hooks/*
```

### Step 6: Smart-merge settings.json

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

Write the merged settings to `<target>/settings.json`.

### Step 7: Print summary

List what was installed:
- Number of skills copied
- Number of commands copied
- Number of sound files copied
- Number of hooks copied
- Settings merged (or created fresh)
- Whether a backup was made
- The target directory



