# claudefiles

Portable Claude Code configuration — like dotfiles, but for Claude.

## Why dotfiles matter

Developers have been versioning their dotfiles for decades. A `.bashrc`, `.vimrc`, `.gitconfig` — these tiny files define how your tools behave. Clone them onto a new machine and you're home. [thoughtbot/dotfiles](https://github.com/thoughtbot/dotfiles) is one of the best examples: a clean, opinionated set of shell, git, and editor configs that thousands of developers fork and customize. The git templates and config in this repo are inspired by theirs.

Claudefiles applies the same idea to Claude Code. Skills, commands, sounds, hooks, and settings — versioned in a repo, deployed to `~/.claude/` on any machine. Your AI assistant, configured exactly how you want it, everywhere.

## Why this exists

I use Claude primarily for two things: managing my personal knowledge system (Obsidian — wiki links, interconnected notes, structured writing) and writing backends in Rust, Golang, and Node.js. This repo is a minimal, portable setup that helps me bootstrap new systems — VMs, servers, side projects, multi-agent architectures where Claude runs not just on my personal machine but across environments. Clone, run Claude, done.

The design assumes Claude is smart enough to read a YAML manifest and configure itself. No complex bash installers. The `/setup` command reads `claudefiles.yaml` and does the right thing — copies files, merges settings, resolves platform differences. Agentic setup over imperative scripting. You should have your own claudefiles too.

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

### Skills (13)

| Skill | Description | Source |
|-------|-------------|--------|
| agent-browser | Browser automation with Playwright | [vercel-labs/agent-browser](https://github.com/vercel-labs/agent-browser) |
| brainstorming | Structured brainstorming sessions | [obra/superpowers](https://github.com/obra/superpowers) |
| breadboarding | UI breadboarding (Shape Up) | [rjs/shaping-skills](https://github.com/rjs/shaping-skills) |
| docx | Word document creation and editing | [anthropics/skills](https://github.com/anthropics/skills) |
| golang-best-practices | Go concurrency, microservices, gRPC, generics | [Jeffallan/claude-skills](https://github.com/Jeffallan/claude-skills) |
| nestjs-best-practices | NestJS architecture and patterns | [Kadajett/agent-nestjs-skills](https://github.com/Kadajett/agent-nestjs-skills) |
| pdf | PDF processing and manipulation | [anthropics/skills](https://github.com/anthropics/skills) |
| pptx | PowerPoint creation | [anthropics/skills](https://github.com/anthropics/skills) |
| react-best-practices | React/Next.js performance patterns | [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills) |
| rust-best-practices | Idiomatic Rust, ownership, error handling, testing | [apollographql/skills](https://github.com/apollographql/skills) |
| shaping | Shape Up project shaping | [rjs/shaping-skills](https://github.com/rjs/shaping-skills) |
| skill-creator | Create and test new skills (TDD methodology) | [anthropics/skills](https://github.com/anthropics/skills) + [obra/superpowers](https://github.com/obra/superpowers) |
| xlsx | Excel spreadsheet processing | [anthropics/skills](https://github.com/anthropics/skills) |

### Commands

| Command | Description |
|---------|-------------|
| `/gcw` | Git commit with conventional commit format |
| `/gitconfig` | Configure git — SSH keys, aliases, templates, hooks (local or global) |
| `/setup` | Install claudefiles to ~/.claude/ |

### Git templates

Opinionated git configuration inspired by [thoughtbot/dotfiles](https://github.com/thoughtbot/dotfiles):

- **gitconfig** — sane defaults: `push.default = current`, `merge.ff = only`, `fetch.prune = true`, useful aliases, commit template, colorMoved
- **gitignore** — global ignores for `.DS_Store`, `.env`, `node_modules`, swap files, build artifacts
- **gitmessage** — commit message template prompting for why, how, and side effects
- **templates/hooks/** — ctags regeneration on commit/merge/checkout/rewrite, local hook delegation

### Hooks

| Hook | Trigger | Description |
|------|---------|-------------|
| shaping-ripple | PostToolUse (Write\|Edit) | When editing a file with `shaping: true` frontmatter, reminds you to maintain consistency — update tables before Mermaid, sync requirements, etc. Silent for all other files. |

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
| marketing-skills | [coreyhaines31/marketingskills](https://github.com/coreyhaines31/marketingskills) | Marketing strategy and content creation |
| cloud-architect | [Jeffallan/claude-skills](https://github.com/Jeffallan/claude-skills) | Cloud architecture patterns and best practices |
| terraform-engineer | [Jeffallan/claude-skills](https://github.com/Jeffallan/claude-skills) | Infrastructure as code with Terraform |
| apollo-client | [apollographql/skills](https://github.com/apollographql/skills) | GraphQL client with caching, suspense, codegen |
| apollo-federation | [apollographql/skills](https://github.com/apollographql/skills) | Federated GraphQL schema composition |
| webapp-testing | [anthropics/skills](https://github.com/anthropics/skills) | Web app testing with Playwright |

## Directory structure

```
claudefiles/
├── bootstrap.sh          # Clone + print setup instructions
├── claudefiles.yaml      # Declarative manifest (source of truth)
├── settings.json         # Reference settings
├── commands/             # Slash commands (.md)
├── dotfiles/                  # Git config, ignore, message template, hooks
│   ├── gitconfig
│   ├── gitignore
│   ├── gitmessage
│   └── templates/hooks/
├── hooks/                # Claude Code hook scripts
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
- [thoughtbot/dotfiles](https://github.com/thoughtbot/dotfiles) — git config, templates, and hooks
- [Jeffallan/claude-skills](https://github.com/Jeffallan/claude-skills) — golang-best-practices
- [apollographql/skills](https://github.com/apollographql/skills) — rust-best-practices
