# Stack

Tools this kit assumes. Each gets one paragraph: what it does, why I chose it, install.

## Claude Code

The agent. Opus 4.7 by default. Everything else in this list is wiring around it.

```bash
# https://docs.anthropic.com/claude-code
```

## addyosmani/agent-skills

The `/spec → /plan → /build` loop. Specs/plans go to `.agent/` (gitignored). Loop scaffolding for any non-trivial change.

```
/plugin marketplace add github:addyosmani/agent-skills
/plugin install agent-skills
```

## caveman

Response compression. Cuts ~75% of fluff without losing technical content. Run in the background, no thinking required.

```
/plugin marketplace add github:JuliusBrussee/caveman
/plugin install caveman
```

## claude-mem

Cross-session memory. Compresses past conversations into a searchable database. Use `mem-search` for "did we solve this before?"

```
/plugin marketplace add github:thedotmack/claude-mem
/plugin install claude-mem
```

## rtk (Rust Token Killer)

Bash output filter. Rewrites `git status` → `rtk git status` transparently via a hook. Saves 60–90% on common dev command tokens.

```bash
brew install rtk-ai/rtk/rtk
# or: cargo install rtk
```

## gh CLI

GitHub CLI. The official one wins over the MCP server by a margin — stateless, scriptable, well-documented.

```bash
brew install gh
gh auth login
```

## Interfaces I keep as MCP

- **Linear** — stateful, official MCP works well
- **Atlassian (Jira/Confluence)** — same reason as Linear
- **Notion** — official MCP, smooth

## Interfaces I dropped MCP for

- **Sentry** → `sentry-cli` (faster, more deterministic)
- **GitHub** → `gh` CLI (by a lot)
- **Playwright** → CLI-driven runs are cleaner than MCP loops
