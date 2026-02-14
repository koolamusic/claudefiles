# claudefiles

Portable Claude Code configuration — like dotfiles, but for Claude. Skills, commands, sounds, and settings that deploy to `~/.claude/` on any machine.

I use Claude mostly to manage my Tesla knowledge system (Obsidian, wiki links, interconnected notes) and to write backends in Rust, Golang, and Node.js. This repo is a minimal, portable setup — it helps me bootstrap new systems, VMs, and servers where I want to run Claude. Clone, run Claude, done.

The design assumes Claude is smart enough to read a YAML manifest and use it to install and configure itself. No complex bash installers, no dependency chains. The `/setup` command reads `claudefiles.yaml` and does the right thing — copies files, merges settings, resolves platform differences. Agentic setup over imperative scripting.

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

| Skill | Description | Source |
|-------|-------------|--------|
| agent-browser | Browser automation with Playwright | [vercel-labs/agent-browser](https://github.com/vercel-labs/agent-browser) |
| brainstorming | Structured brainstorming sessions | [obra/superpowers](https://github.com/obra/superpowers) |
| breadboarding | UI breadboarding (Shape Up) | [rjs/shaping-skills](https://github.com/rjs/shaping-skills) |
| docx | Word document creation and editing | [anthropics/skills](https://github.com/anthropics/skills) |
| nestjs-best-practices | NestJS architecture and patterns | [Kadajett/agent-nestjs-skills](https://github.com/Kadajett/agent-nestjs-skills) |
| pdf | PDF processing and manipulation | [anthropics/skills](https://github.com/anthropics/skills) |
| pptx | PowerPoint creation | [anthropics/skills](https://github.com/anthropics/skills) |
| react-best-practices | React/Next.js performance patterns | [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills) |
| shaping | Shape Up project shaping | [rjs/shaping-skills](https://github.com/rjs/shaping-skills) |
| skill-creator | Create and test new skills (TDD methodology) | [anthropics/skills](https://github.com/anthropics/skills) + [obra/superpowers](https://github.com/obra/superpowers) |
| webapp-testing | Web application testing | [anthropics/skills](https://github.com/anthropics/skills) |
| xlsx | Excel spreadsheet processing | [anthropics/skills](https://github.com/anthropics/skills) |

### Commands

| Command | Description |
|---------|-------------|
| `/gcw` | Git commit with conventional commit format |
| `/gitconfig` | Configure per-repo SSH key (multi-account GitHub) |
| `/setup` | Install claudefiles to ~/.claude/ |

### Sounds

SCV-themed audio cues for Claude Code hooks — startup, prompt submission, and task completion.

## Other skills worth checking out

Great skills that didn't make the bootstrap cut — either too project-specific, experimental, or you'd add them per-project rather than globally:

| Skill | Source | Why it's interesting |
|-------|--------|---------------------|
| systematic-debugging | [obra/superpowers](https://github.com/obra/superpowers) | Root cause tracing, defense-in-depth debugging |
| test-driven-development | [obra/superpowers](https://github.com/obra/superpowers) | TDD cycle enforcement with anti-pattern detection |
| subagent-driven-development | [obra/superpowers](https://github.com/obra/superpowers) | Dispatch parallel subagents for implementation tasks |
| writing-plans | [obra/superpowers](https://github.com/obra/superpowers) | Structured planning with execution handoff |
| algorithmic-art | [anthropics/skills](https://github.com/anthropics/skills) | Generate algorithmic art with JS |
| canvas-design | [anthropics/skills](https://github.com/anthropics/skills) | Design with HTML5 Canvas |
| brand-guidelines | [anthropics/skills](https://github.com/anthropics/skills) | Maintain brand consistency in outputs |

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

## License

MIT

## Acknowledgments

Most skills here weren't written by me. This repo curates and organizes work from:
- [Anthropic](https://github.com/anthropics/skills) — official skills (pdf, docx, xlsx, pptx, webapp-testing, skill-creator)
- [obra/superpowers](https://github.com/obra/superpowers) — brainstorming, writing-skills, TDD methodology
- [vercel-labs](https://github.com/vercel-labs) — agent-browser, react-best-practices
- [rjs/shaping-skills](https://github.com/rjs/shaping-skills) — Shape Up shaping and breadboarding
- [Kadajett/agent-nestjs-skills](https://github.com/Kadajett/agent-nestjs-skills) — NestJS best practices
