---
name: gitconfig
allowed-tools: Bash(ssh-keygen:*), Bash(ssh -T:*), Bash(ssh -o:*), Bash(ssh-add:*), Bash(git config:*), Bash(ls:*), Bash(cat:*)
description: Configure per-repo SSH key for Git operations (multi-account GitHub setup)
---

## Context

When you have multiple GitHub accounts, SSH may authenticate with the wrong account because the SSH agent offers keys in order and GitHub accepts the **first valid key** — regardless of which repo you're pushing to.

**Key insight:** `IdentitiesOnly=yes` alone is NOT enough. Keys loaded in the SSH agent that match `IdentityFile` entries in `~/.ssh/config` still get offered. You must also set `IdentityAgent=none` to fully bypass the agent.

## Your task

### Step 1: List available SSH keys

```bash
ls -la ~/.ssh/*.pub
```

Present the keys to the user and ask which one to use for this repo.

### Step 2: Test the selected key

```bash
ssh -o IdentitiesOnly=yes -o IdentityAgent=none -i ~/.ssh/<selected_key> -T git@github.com
```

Show which GitHub account the key maps to. Ask the user to confirm this is correct.

### Step 3: Confirm current repo and remote

```bash
git remote -v
```

Show the current repo remote URL and confirm with the user.

### Step 4: Configure per-repo SSH command

```bash
git config core.sshCommand "ssh -o IdentitiesOnly=yes -o IdentityAgent=none -i ~/.ssh/<selected_key>"
```

The three flags work together:

| Flag | Purpose |
|------|---------|
| `IdentitiesOnly=yes` | Only use explicitly configured identity files |
| `IdentityAgent=none` | Completely bypass SSH agent (prevents agent-cached keys from interfering) |
| `-i <key>` | Specify exactly which private key to use |

### Step 5: Verify configuration

```bash
git config --local core.sshCommand
```

Confirm the setting is stored in `.git/config` (repo-scoped only).

### Step 6: Test end-to-end

```bash
ssh -o IdentitiesOnly=yes -o IdentityAgent=none -i ~/.ssh/<selected_key> -T git@github.com
```

Confirm authentication succeeds with the correct account.

## Alternative approach

If the user prefers a global solution (same account across many repos), suggest SSH config host alias:

```
# In ~/.ssh/config
Host github-<account>
  HostName github.com
  IdentityFile ~/.ssh/<key>
  IdentitiesOnly yes
  IdentityAgent none
```

Then update remote: `git remote set-url origin git@github-<account>:<user>/<repo>.git`

## Quick reference

```bash
# Set per-repo SSH key
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
