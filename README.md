# dominikwozniak-skills

An opinionated Claude Code starter kit. Drop into any project, get a working AI dev setup in seconds.

## What you get

- **Workflow loop** — `/spec → /plan → /build` via [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills). Plans land in `.agent/` (gitignored), nothing leaks into PRs.
- **Configurable git skill** (`git-workflow`) — commit, push, PR, sync. Reads conventions from your `CLAUDE.local.md`; falls back to sensible defaults.
- **Guardrails** — blocks dangerous git operations (`--force` push, `reset --hard`, `clean -f`, etc.) via a Claude Code `PreToolUse` hook. Ask-list permissions for the rest.
- **Autoloop quality hooks** — lints on edit, typechecks on stop. Failures surface to the agent via stderr so it can self-correct.
- **Session handoff skill** — compact the current conversation into `.agent/handoffs/<ts>.md` so another agent (fresh Claude Code, Codex, etc.) can continue.
- **Pre-commit setup skill** — husky + lint-staged + prettier in one command. Team-shared, opt-in.

## Install

### One-time: add this marketplace

In Claude Code:

```
/plugin marketplace add github:dominikwozniak/dominikwozniak-skills
```

### Per project: bootstrap

```bash
~/path/to/dominikwozniak-skills/scripts/bootstrap.sh /path/to/your/project
```

Drops everything **local-only** (gitignored): `CLAUDE.local.md`, `.claude/settings.local.json`, `.claude/hooks/*.sh`, and updates `.gitignore` to include `.agent/`.

### Enable plugins

In Claude Code, inside your project:

```
/plugin install bootstrap-workflow
/plugin install git-workflow
/plugin install session-handoff
/plugin install setup-pre-commit   # only if your team wants husky + lint-staged
```

## Recommended companion plugins

These aren't bundled here — install them separately for the full experience:

- [`agent-skills`](https://github.com/addyosmani/agent-skills) — the `/spec → /plan → /build` loop
- [`caveman`](https://github.com/JuliusBrussee/caveman) — token-saving response compression
- [`claude-mem`](https://github.com/thedotmack/claude-mem) — cross-session memory
- [`rtk`](https://github.com/rtk-ai/rtk) — Bash output filter (CLI install, not a CC plugin)

## Layout

```
.
├── docs/                      # Stack, workflow, conventions, guardrails
├── templates/                 # Drop-in artifacts (used by bootstrap)
├── plugins/                   # bootstrap-workflow, git-workflow, session-handoff, setup-pre-commit
├── scripts/                   # bootstrap.sh, doctor.sh
└── .claude-plugin/            # marketplace.json
```

## Philosophy

- **Local-first** — everything bootstrap drops is gitignored. No teammate impact.
- **Reuse upstream** — addyosmani's loop, mattpocock's handoff/guardrail patterns, ahplus-web hook patterns. We add the glue.
- **Configurable** — `git-workflow` reads `CLAUDE.local.md`. Defaults if absent.
- **Lean** — no `agnix` lint, no `deno fmt` enforcement, no plugin marketplace machinery beyond what's needed.

## License

MIT
