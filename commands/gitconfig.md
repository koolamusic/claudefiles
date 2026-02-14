---
name: gitconfig
allowed-tools: Bash(ssh-keygen:*), Bash(ssh -T:*), Bash(ssh -o:*), Bash(ssh-add:*), Bash(git config:*), Bash(ls:*), Bash(cat:*), Bash(cp:*), Bash(mkdir:*), Bash(chmod:*), Read
description: Configure git — SSH keys, aliases, templates, hooks, and ignore rules. Supports both per-repo (local) and global setup.
---

## Context

This command configures git at two levels:

- **Local** (per-repo): SSH key for multi-account GitHub setups
- **Global** (machine-wide): aliases, commit template, ignore rules, hooks, and sane defaults

The git templates in this repo (`dotfiles/`) are inspired by [thoughtbot/dotfiles](https://github.com/thoughtbot/dotfiles).

## Your task

### Step 0: Ask scope

Ask the user: **local** (configure SSH key for this repo) or **global** (set up git config, templates, hooks for the whole machine)?

---

## Local mode: Per-repo SSH key

When you have multiple GitHub accounts, SSH may authenticate with the wrong account because the SSH agent offers keys in order and GitHub accepts the **first valid key**.

**Key insight:** `IdentitiesOnly=yes` alone is NOT enough. Keys loaded in the SSH agent that match `IdentityFile` entries in `~/.ssh/config` still get offered. You must also set `IdentityAgent=none` to fully bypass the agent.

### Step 1: List available SSH keys

```bash
ls -la ~/.ssh/*.pub
```

Present the keys and ask which one to use.

### Step 2: Test the selected key

```bash
ssh -o IdentitiesOnly=yes -o IdentityAgent=none -i ~/.ssh/<selected_key> -T git@github.com
```

Show which GitHub account the key maps to. Confirm with the user.

### Step 3: Confirm current repo and remote

```bash
git remote -v
```

### Step 4: Configure per-repo SSH command

```bash
git config core.sshCommand "ssh -o IdentitiesOnly=yes -o IdentityAgent=none -i ~/.ssh/<selected_key>"
```

| Flag | Purpose |
|------|---------|
| `IdentitiesOnly=yes` | Only use explicitly configured identity files |
| `IdentityAgent=none` | Completely bypass SSH agent (prevents agent-cached keys from interfering) |
| `-i <key>` | Specify exactly which private key to use |

### Step 5: Verify

```bash
git config --local core.sshCommand
ssh -o IdentitiesOnly=yes -o IdentityAgent=none -i ~/.ssh/<selected_key> -T git@github.com
```

---

## Global mode: Machine-wide git setup

Read the git templates from this repo's `dotfiles/` directory and install them system-wide.

### Step 1: Install gitconfig

Read `dotfiles/gitconfig` from this repo. Ask the user for their name and email, then install:

```bash
# Copy as base config
cp dotfiles/gitconfig ~/.gitconfig

# Set user identity
git config --global user.name "<name>"
git config --global user.email "<email>"
```

This sets up:
- `push.default = current` — push current branch to same-name remote
- `merge.ff = only` — no merge commits for fast-forwards
- `fetch.prune = true` — clean up stale remote branches
- `rebase.autosquash = true` — auto-reorder fixup commits
- `diff.colorMoved = zebra` — highlight moved lines in diffs
- `init.defaultBranch = main`
- Useful aliases: `aa`, `ap`, `branches`, `ci`, `co`, `pf`, `st`
- `include.path = ~/.gitconfig.local` — for machine-specific overrides

### Step 2: Install global gitignore

```bash
cp dotfiles/gitignore ~/.gitignore
git config --global core.excludesfile ~/.gitignore
```

Ignores `.DS_Store`, `.env`, `node_modules`, swap files, build artifacts, log files.

### Step 3: Install commit template

```bash
cp dotfiles/gitmessage ~/.gitmessage
git config --global commit.template ~/.gitmessage
```

Prompts for: why the change was necessary, how it addresses the problem, side effects, and co-authors.

### Step 4: Install git template directory (hooks)

```bash
mkdir -p ~/.git_template/hooks
cp dotfiles/templates/hooks/* ~/.git_template/hooks/
chmod +x ~/.git_template/hooks/*
git config --global init.templatedir ~/.git_template
```

Hooks included:
- **ctags** — regenerate tags from git-tracked files
- **post-commit, post-merge, post-checkout, post-rewrite** — auto-run ctags
- **pre-commit, pre-push, commit-msg, prepare-commit-msg** — delegate to `~/.git_template.local/hooks/` for custom local hooks

### Step 5: Print summary

Show what was installed and remind the user:
- `~/.gitconfig.local` can override any setting (included automatically)
- `~/.git_template.local/hooks/` can add custom hooks per-machine
- Existing repos need `git init` to pick up new template hooks

## Quick reference

```bash
# Per-repo SSH key
git config core.sshCommand "ssh -o IdentitiesOnly=yes -o IdentityAgent=none -i ~/.ssh/YOUR_KEY"

# Test which account a key authenticates as
ssh -o IdentitiesOnly=yes -o IdentityAgent=none -i ~/.ssh/YOUR_KEY -T git@github.com

# List loaded agent keys
ssh-add -l

# Check key fingerprint
ssh-keygen -lf ~/.ssh/YOUR_KEY

# See current repo SSH config
git config --local core.sshCommand

# Remove the override (revert to default)
git config --local --unset core.sshCommand
```
