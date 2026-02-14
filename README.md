# claudefiles

Portable Claude Code configuration — like dotfiles, but for Claude. Skills, commands, sounds, and settings that deploy to `~/.claude/` on any machine.

## Quick install

```bash
curl -fsSL https://raw.githubusercontent.com/koolamusic/claudefiles/main/bootstrap.sh | bash
```

Or manually:

```bash
git clone git@github.com:koolamusic/claudefiles.git ~/.claudefiles
cd ~/.claudefiles && claude "/setup"
```

The bootstrap script clones the repo. Then `/setup` (a Claude Code slash command) reads `claudefiles.yaml` and copies everything into `~/.claude/`.

## What's included

### Skills (12)

| Skill | Description |
|-------|-------------|
| agent-browser | Browser automation with Playwright |
| brainstorming | Structured brainstorming sessions |
| breadboarding | UI breadboarding (Shape Up) |
| docx | Word document creation and editing |
| nestjs-best-practices | NestJS architecture and patterns |
| pdf | PDF processing and manipulation |
| pptx | PowerPoint creation |
| react-best-practices | React/Next.js performance patterns |
| shaping | Shape Up project shaping |
| skill-creator | Create and test new skills (TDD methodology) |
| webapp-testing | Web application testing |
| xlsx | Excel spreadsheet processing |

### Commands

| Command | Description |
|---------|-------------|
| `/gcw` | Git commit with conventional commit format |
| `/ssh-git-config` | Configure per-repo SSH key (multi-account GitHub) |
| `/setup` | Install claudefiles to ~/.claude/ |

### Sounds

SCV-themed audio cues for Claude Code hooks — startup, prompt submission, and task completion.

## Directory structure

```
claudefiles/
├── bootstrap.sh          # Clone + print setup instructions
├── claudefiles.yaml      # Declarative manifest (source of truth)
├── settings.json         # Reference settings
├── commands/             # Slash commands (.md)
├── sounds/               # Audio files (.wav)
└── skills/               # Skill directories (SKILL.md + resources)
```

## Adding new skills

1. Create a directory under `skills/` with a `SKILL.md` file
2. Use `/skill-creator` for guidance on structure and testing
3. Re-run `/setup` to deploy

## Adding new commands

1. Create a `.md` file under `commands/` with YAML frontmatter (`name`, `allowed-tools`, `description`)
2. Re-run `/setup` to deploy

## Configuration

`claudefiles.yaml` is the source of truth. It declares:
- **install.targets** — what directories to copy and where
- **settings** — hooks, plugins, and preferences to merge into settings.json
- **platform** — OS-specific values (sound player binary)
