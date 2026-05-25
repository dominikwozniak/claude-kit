# 🧰 claude-kit

An opinionated Claude Code starter kit. Drop it into any project and get the same sane AI dev loop everywhere.

claude-kit is the toolbox I wish every Claude Code repo had on day one — bootstrap, git workflow, session handoff, optional pre-commit, plus the guardrails to keep the agent (and me, at 2am) from breaking things. Install once from the marketplace; bootstrap each project in seconds.

## 🤔 Why it exists

Every Claude Code project I touch needs the same things wired up, and I got tired of doing it from scratch:

- **Specs and plans leak into PRs.** The `/spec → /plan → /build` loop is great until a draft spec ends up in `main` because it sat in the repo root. claude-kit drops everything into `.agent/`, gitignored.
- **Dangerous git ops are too easy.** Agents (and humans at 2am) reach for `--force` push or `reset --hard`. A `PreToolUse` hook hard-blocks the destructive patterns; risky-but-fine commands drop to a one-tap ask.
- **Conventions drift between repos.** Commit format, default branch, lint command — every codebase is different. `git-workflow` reads `CLAUDE.local.md` per invocation, falls back to sensible defaults.
- **Session context dies between agents.** Switching from Claude to Codex (or just a new session) means re-explaining everything. `session-handoff` compacts the current session into `.agent/handoffs/<ts>.md`.
- **Pre-commit only binds me.** Local hooks don't enforce the team. `setup-pre-commit` commits husky + lint-staged + prettier so everyone is on the same hook.

Underneath: a tiny PreToolUse hook that blocks `npm`/`yarn`/`bun` so the agent can't sneak a non-pnpm install into a pnpm project.

## 🚀 Quick start

Add the marketplace once, then install plugins:

```
claude plugin marketplace add git@github.com:dominikwozniak/claude-kit.git
claude plugin install bootstrap-workflow
claude plugin install git-workflow
claude plugin install session-handoff
claude plugin install setup-pre-commit   # only if your team wants husky + lint-staged
```

Then, inside any project you want to bootstrap, invoke the `bootstrap-workflow` skill. Claude runs `${CLAUDE_PLUGIN_ROOT}/scripts/bootstrap.sh "$(pwd)"`, drops the local-only artifacts, and you're done. No clone of this repo required.

> Contributing to claude-kit? Clone it and run `scripts/bootstrap.sh /path/to/your/project` directly — handy for testing template changes against a real project.

## 📦 What you get

Four plugins, each solving one concrete pain. Install only what you need.

**`bootstrap-workflow`** — Runs `bootstrap.sh` against the current project. À la carte picker (via `AskUserQuestion`): pick which artifacts you want, which hooks to wire, and which missing deps to `brew install`. Pre-checks defaults from the repo's actual stack (no `block-non-pnpm` if there's no `package.json`, no `typecheck-on-stop` if there's no `tsconfig.json`). Stack-aware: Ruby/Rails repos get `bundle exec rspec` + `standardrb`/`rubocop` defaults in `CLAUDE.local.md` and the JS-only hooks are skipped entirely. Every drop is local and gitignored, so re-running is always safe. Use it for the first setup in any new repo.

**`git-workflow`** — A single configurable commit / push / PR / sync skill. Reads `CLAUDE.local.md` for per-repo conventions (commit format, default branch, PR template), falls back to defaults when the file is missing. Replaces five drive-by commands with one that knows the project.

**`session-handoff`** — Compacts the current session into `.agent/handoffs/<YYYYMMDD-HHMM>.md`. Pick it up in a fresh Claude Code session, or hand it to another agent. Use when context gets long or you want a clean continuation.

**`setup-pre-commit`** — Installs husky + lint-staged + prettier and commits the config. The one bootstrap step that affects teammates — they get the same pre-commit hook on next `pnpm install`.

## 🔁 The daily loop

claude-kit pairs with [`addyosmani/agent-skills`](https://github.com/addyosmani/agent-skills) for the actual development loop:

```
/spec   → write a structured spec for the change
/plan   → break it into ordered, verifiable tasks
/build  → implement incrementally with tests
```

Everything those skills write goes into `.agent/` — gitignored by `bootstrap.sh`, so nothing leaks into PRs. The full lifecycle extends with `/test`, `/review`, `/ship` when you want them; the triplet above is the daily working set.

## 🧩 Companion plugins

Not bundled here. Install separately for the full experience:

- [`agent-skills`](https://github.com/addyosmani/agent-skills) — the `/spec → /plan → /build` loop and related skills
- [`caveman`](https://github.com/JuliusBrussee/caveman) — token-saving response compression
- [`claude-mem`](https://github.com/thedotmack/claude-mem) — cross-session memory
- [`rtk`](https://github.com/rtk-ai/rtk) — Bash output filter (CLI install, not a Claude Code plugin)

## 🏗️ How bootstrap works

`bootstrap.sh` writes only **local, gitignored** artifacts into the target repo:

```
<your-project>/
├── CLAUDE.local.md            # personal agent memory (gitignored)
├── .claude/
│   ├── settings.local.json    # hook wiring + permissions
│   └── hooks/
│       ├── block-dangerous-git.sh
│       ├── block-non-pnpm.sh
│       ├── lint-on-edit.sh
│       └── typecheck-on-stop.sh
├── .agent/                    # plans, specs, handoffs (gitignored)
└── .gitignore                 # appended with .agent/, CLAUDE.local.md, settings.local.json, hooks
```

Selection is the gate: only what you tick in the picker gets written. The `.gitignore` block is marker-fenced and idempotent, so re-running with the same selection is a no-op. De-selecting a hook later does not delete a previously installed file — drop it by hand if you want it gone.

`setup-pre-commit` is the one exception — it **commits** husky + lint-staged config so the whole team is bound.

### Direct invocation

Outside Claude, run the script yourself:

```bash
scripts/bootstrap.sh /path/to/project                                  # all features, all hooks (default)
scripts/bootstrap.sh /path/to/project --features=claude-md --hooks=    # CLAUDE.local.md only
scripts/bootstrap.sh /path/to/project --no-prompt --project-name=foo   # CI-safe, flag-driven
scripts/doctor.sh --json                                               # machine-readable health check
```

Flags: `--features=claude-md,settings,gitignore`, `--hooks=block-dangerous-git,block-non-pnpm,lint-on-edit,typecheck-on-stop`, `--brew-install=<tool,...>`, `--project-name=`, `--default-branch=`, `--stack=`, `--test-cmd=`, `--lint-cmd=`, `--typecheck-cmd=`, `--domain=`, `--key-dirs=`, `--deploy=`, `--gotchas=`, `--no-prompt`. Anything you omit falls back to interactive prompt (unless `--no-prompt`) or auto-detection.

## ✅ Quality bar

The repo holds itself to the same bar it wires into target projects:

- `pnpm lint` — [`agnix`](https://github.com/agnix-dev/agnix) validates CLAUDE.md, SKILL.md, hooks, manifests (`.agnix.toml`, `templates/` excluded — placeholders, not real configs)
- `pnpm format` — `prettier --check` on md/json/yaml (`proseWrap: preserve` so SKILL.md trigger tokens aren't rewrapped)
- `pnpm validate:manifests` — `claude plugin validate` on every `marketplace.json` and `plugin.json`, plus a version sync check between marketplace entries and plugin manifests

All three run in CI on `pull_request` and `push` to `main`; actions SHA-pinned, runner `ubuntu-latest`.

## 📁 Layout

```
.
├── skills/                    # Canonical SKILL.md files (flat: skills/<name>/SKILL.md)
├── docs/                      # Stack, workflow, conventions, guardrails
├── templates/                 # Drop-in artifacts (canonical; symlinked into bootstrap-workflow plugin)
├── scripts/                   # bootstrap.sh, doctor.sh (canonical; symlinked into bootstrap-workflow plugin)
├── plugins/                   # Plugin manifests. Symlinks in each plugin:
│                              #   plugins/<name>/skills/<name>       → ../../../skills/<name>
│                              #   plugins/bootstrap-workflow/scripts → ../../scripts
│                              #   plugins/bootstrap-workflow/templates → ../../templates
└── .claude-plugin/            # marketplace.json
```

Every skill's canonical file lives in `skills/<name>/SKILL.md`. Each plugin's `skills/<name>` is a git-tracked symlink pointing back at the canonical file — edit in `skills/`, never via the symlink. Windows clones need `git config --global core.symlinks true`.

## 📜 License

MIT
