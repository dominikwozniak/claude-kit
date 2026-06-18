# 🧰 claude-kit

> ## ⚠️ Deprecated — archived
>
> Superseded by **[dominikwozniak-skills](https://github.com/dominikwozniak/dominikwozniak-skills)**,
> which ships the same workflow as `dw-*` skills. Install that marketplace instead.
>
> | claude-kit plugin    | replacement                                                                              |
> | -------------------- | ---------------------------------------------------------------------------------------- |
> | `bootstrap-workflow` | `dw-bootstrap`                                                                           |
> | `git-workflow`       | `dw-git`                                                                                 |
> | `session-handoff`    | `dw-handoff`                                                                             |
> | `setup-pre-commit`   | _no direct successor_ — git pre-commit layer; recover from this repo's history if needed |
>
> This repository is **archived** (read-only). History is preserved.

An opinionated Claude Code starter kit. Drop it into any project and get the same sane AI dev loop
everywhere — bootstrap, git workflow, session handoff, optional pre-commit, plus the guardrails to
keep the agent from breaking things.

## 🚀 Quick start

```
claude plugin marketplace add git@github.com:dominikwozniak/claude-kit.git
claude plugin install bootstrap-workflow
claude plugin install git-workflow
claude plugin install session-handoff
claude plugin install setup-pre-commit   # only if your team wants husky + lint-staged
```

Then invoke the `bootstrap-workflow` skill inside any project — it runs `bootstrap.sh`, drops the
local-only (gitignored) artifacts, and you're done. No clone of this repo required. Direct
invocation and flags: `scripts/bootstrap.sh --help`.

## 📦 Plugins

- **`bootstrap-workflow`** — runs `bootstrap.sh` on a project; à la carte picker for artifacts,
  hooks, and deps. Stack-aware (JS / Ruby).
- **`git-workflow`** — one commit / push / PR / sync skill; reads per-repo conventions from
  `CLAUDE.local.md`, falls back to defaults.
- **`session-handoff`** — compacts the session into `.agent/handoffs/<ts>.md` for a clean
  continuation in a fresh session or another agent.
- **`setup-pre-commit`** — commits husky + lint-staged + prettier so the whole team shares the same
  hook.

## 📚 More

- [`docs/workflow.md`](docs/workflow.md) — the `/spec → /plan → /build` daily loop and conventions
- [`docs/stack.md`](docs/stack.md) — companion tools (agent-skills, caveman, claude-mem, rtk, gh)
- [`docs/guardrails.md`](docs/guardrails.md) — git block / ask guardrails
- [`docs/conventions.md`](docs/conventions.md) — commit / branch / PR conventions
- [`AGENTS.md`](AGENTS.md) — repo layout and contributor guide (`CLAUDE.md` is a symlink to it)

## 📜 License

MIT
