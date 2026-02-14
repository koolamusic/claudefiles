# claudefiles

Portable Claude Code configuration — like dotfiles, but for Claude.

This repo is **opinionated toward Claude Code**. It does not support other AI coding assistants and has no plans to. If you want multi-agent compatibility, this is not the repo for you.

## About

Developers have been versioning their dotfiles for decades. A `.bashrc`, `.vimrc`, `.gitconfig` — these tiny files define how your tools behave. Clone them onto a new machine and you're home.

Claudefiles applies the same idea to Claude Code. Skills, commands, hooks, sounds, and settings — versioned in a repo, deployed to `~/.claude/` on any machine. Your AI assistant, configured exactly how you want it, everywhere.

> **Note:** This is my personal configuration. I use Claude primarily for managing my knowledge system (Obsidian) and writing backends in Rust, Golang, and Node.js. The skills, hooks, and settings reflect those workflows. Fork and customize — that's what dotfiles are for.

## Installing

### Quick install

```bash
curl -fsSL https://raw.githubusercontent.com/koolamusic/claudefiles/main/bootstrap.sh | bash
```

This clones the repo to `~/.claudefiles`. Then run Claude to deploy:

```bash
cd ~/.claudefiles && claude "/setup"
```

### Manual install

```bash
git clone git@github.com:koolamusic/claudefiles.git ~/.claudefiles
cd ~/.claudefiles && claude "/setup"
```

### What `/setup` does

The `/setup` command reads `claudefiles.yaml` (the manifest) and:

1. Detects your platform (macOS or Linux)
2. Copies skills, commands, hooks, and sounds to `~/.claude/`
3. Smart-merges settings into `~/.claude/settings.json` (backs up existing settings first)
4. Resolves platform-specific template variables (e.g., `afplay` vs `aplay` for sound)

### Git configuration (separate step)

Git templates are installed separately because they go to `~/.gitconfig`, not `~/.claude/`:

```bash
claude "/gitconfig"
```

This installs sane git defaults, a global gitignore, commit message template, and ctags hooks. Inspired by [thoughtbot/dotfiles](https://github.com/thoughtbot/dotfiles).

## What's included

### Skills

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

| Command | What it does |
|---------|-------------|
| `/gcw` | Git commit with conventional commit format |
| `/gitconfig` | Configure git — SSH keys, aliases, templates, hooks (local or global) |
| `/setup` | Install claudefiles to `~/.claude/` |

### Hooks

| Hook | Trigger | What it does |
|------|---------|-------------|
| shaping-ripple | PostToolUse (Write\|Edit) | When editing a file with `shaping: true` frontmatter, prints a ripple-check reminder to keep tables, diagrams, and requirements in sync. Silent for all other files. |

### Sounds

SCV-themed audio cues (StarCraft). Claude plays a voice line on startup, when you submit a prompt, and when a task finishes.

| Event | Sound |
|-------|-------|
| Session start | "SCV good to go, sir!" |
| Prompt submit | Random acknowledgment (7 variants) |
| Task complete | Random completion (3 variants) |

### Git templates

Opinionated git configuration installed via `/gitconfig`:

- **gitconfig** — `push.default = current`, `merge.ff = only`, `fetch.prune = true`, useful aliases, commit template, colorMoved
- **gitignore** — global ignores for `.DS_Store`, `.env`, `node_modules`, swap files, build artifacts
- **gitmessage** — commit template prompting for why, how, and side effects
- **tmux.conf** — tmux configuration
- **templates/hooks/** — ctags regeneration on commit/merge/checkout/rewrite, local hook delegation

## Configuration

`claudefiles.yaml` is the source of truth. It declares:

- **install.targets** — what directories to copy and where
- **settings** — hooks, plugins, and preferences to merge into `settings.json`
- **platform** — OS-specific values (sound player binary)

```
claudefiles/
├── bootstrap.sh              # Clone + print setup instructions
├── claudefiles.yaml          # Manifest (source of truth)
├── settings.json             # Reference settings (final structure)
├── CLAUDE.md                 # Repo architecture for Claude
├── commands/                 # Slash commands (.md)
│   ├── gitcommit.md
│   ├── gitconfig.md
│   └── setup.md
├── dotfiles/                 # Git config, ignore, message template, hooks
│   ├── gitconfig
│   ├── gitignore
│   ├── gitmessage
│   ├── tmux.conf
│   └── templates/hooks/
├── hooks/                    # Claude Code hook scripts
│   └── shaping-ripple.sh
├── sounds/                   # SCV audio files (.wav)
└── skills/                   # Skill directories
    ├── agent-browser/
    ├── brainstorming/
    ├── breadboarding/
    │   ├── SKILL.md
    │   ├── references/       # Progressive-disclosure docs (8 files)
    │   └── scripts/          # preview-markdown.sh
    ├── ...
    └── xlsx/
```

## Extending

### Add a skill

1. Create a directory under `skills/` with a `SKILL.md` file
2. Include YAML frontmatter: `name` and `description`
3. Use `/skill-creator` for guidance on structure and testing
4. Run `/setup` to deploy

### Add a command

1. Create a `.md` file under `commands/` with YAML frontmatter (`name`, `allowed-tools`, `description`)
2. Run `/setup` to deploy

### Add a hook

1. Create an executable script in `hooks/`
2. Include a YAML-style documentation header in comments
3. Add the corresponding trigger to `claudefiles.yaml` under `settings.hooks`
4. Run `/setup` to deploy

## Other skills worth checking out

Skills that didn't make the bootstrap cut — too project-specific, experimental, or better added per-project:

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

## Contributing

**Issues first, always.** Every contribution starts with an issue. PRs without an approved issue will be closed — no exceptions. If I agree with your issue, I'll implement it or invite you to submit a PR.

If you want to extend this for your own use, fork it. That's the whole point of dotfiles.

See [CONTRIBUTING.md](./CONTRIBUTING.md) for details.

## Future work

**Claudefiles spec** — a formal specification for the `claudefiles.yaml` manifest format. Schema, validation, versioning, cross-repo compatibility. This would let anyone create interoperable claudefiles repos. Not tackling yet, but it's the natural next step.

## License

[MIT](./LICENSE)

## Acknowledgments

Most skills here weren't written by me. This repo curates and organizes work from:

- [Anthropic](https://github.com/anthropics/skills) — official skills (pdf, docx, xlsx, pptx, skill-creator)
- [obra/superpowers](https://github.com/obra/superpowers) — brainstorming, writing-skills, TDD methodology
- [vercel-labs](https://github.com/vercel-labs) — agent-browser, react-best-practices
- [rjs/shaping-skills](https://github.com/rjs/shaping-skills) — Shape Up shaping and breadboarding
- [Kadajett/agent-nestjs-skills](https://github.com/Kadajett/agent-nestjs-skills) — NestJS best practices
- [thoughtbot/dotfiles](https://github.com/thoughtbot/dotfiles) — git config, templates, and hooks
- [Jeffallan/claude-skills](https://github.com/Jeffallan/claude-skills) — golang-best-practices
- [apollographql/skills](https://github.com/apollographql/skills) — rust-best-practices
- [htjun/claude-code-hooks-scv-sounds](https://github.com/htjun/claude-code-hooks-scv-sounds) — SCV sound files
