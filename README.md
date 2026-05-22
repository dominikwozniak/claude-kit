# claude-kit

An opinionated Claude Code starter kit. Drop into any project, get a working AI dev setup in seconds.

## Quick start

In Claude Code, add the marketplace and install the plugins (one time):

```
/plugin marketplace add github:dominikwozniak/claude-kit
/plugin install bootstrap-workflow
/plugin install git-workflow
/plugin install session-handoff
/plugin install setup-pre-commit   # only if your team wants husky + lint-staged
```

Then, inside any project you want to bootstrap, invoke the `bootstrap-workflow` skill. Claude runs `${CLAUDE_PLUGIN_ROOT}/scripts/bootstrap.sh "$(pwd)"` and drops the local-only, gitignored artifacts. No clone of this repo required.

> Contributing to claude-kit? Clone it and run `scripts/bootstrap.sh /path/to/your/project` directly — handy for testing template changes.

## Plugins

| Plugin               | What it does                                                       | Use when                       |
| -------------------- | ------------------------------------------------------------------ | ------------------------------ |
| `bootstrap-workflow` | Runs `bootstrap.sh` against the current project                    | First setup in any new repo    |
| `git-workflow`       | Commit / push / PR / sync, reads `CLAUDE.local.md` for conventions | Daily git work                 |
| `session-handoff`    | Compacts session into `.agent/handoffs/<ts>.md`                    | Switching agents or sessions   |
| `setup-pre-commit`   | Installs husky + lint-staged + prettier (team-shared, committed)   | Team wants enforced pre-commit |

Every skill's canonical file lives in `skills/<name>/SKILL.md`. Each plugin's `skills/<name>` is a git-tracked symlink pointing back at the canonical file — edit in `skills/`, never via the symlink. Windows clones need `git config --global core.symlinks true`.

## How it works

`bootstrap.sh` writes only **local, gitignored** artifacts into the target repo:

```
<your-project>/
├── CLAUDE.local.md            # personal agent memory (gitignored)
├── .claude/
│   ├── settings.local.json    # hook wiring + permissions
│   └── hooks/
│       ├── block-dangerous-git.sh
│       ├── lint-on-edit.sh
│       └── typecheck-on-stop.sh
├── .agent/                    # plans, specs, handoffs (gitignored)
└── .gitignore                 # appended with .agent/ + .claude/settings.local.json
```

`setup-pre-commit` is the one exception — it **commits** husky/lint-staged config so the whole team is bound.

## Companion plugins

Not bundled here. Install separately for the full experience:

- [`agent-skills`](https://github.com/addyosmani/agent-skills) — the `/spec → /plan → /build` loop
- [`caveman`](https://github.com/JuliusBrussee/caveman) — token-saving response compression
- [`claude-mem`](https://github.com/thedotmack/claude-mem) — cross-session memory
- [`rtk`](https://github.com/rtk-ai/rtk) — Bash output filter (CLI install, not a CC plugin)

## Why

**Plans leak into PRs.** Spec/plan drafts end up committed by accident. Here, `/spec → /plan → /build` writes everything to `.agent/`, which `bootstrap.sh` adds to `.gitignore`. Nothing leaks.

**Dangerous git ops happen too easily.** Agents and humans both run `--force` push or `reset --hard` at 2am. A `PreToolUse` Bash hook hard-blocks the destructive patterns; non-destructive risk (`rm *`, `sudo`, `gh repo delete`) drops to one-tap ask.

**Conventions drift between projects.** Commit format, default branch, lint command — every repo is different. `git-workflow` reads `CLAUDE.local.md` per invocation. Defaults apply when the file is absent.

## Layout

```
.
├── skills/                    # Canonical SKILL.md files (flat: skills/<name>/SKILL.md)
├── docs/                      # Stack, workflow, conventions, guardrails
├── templates/                 # Drop-in artifacts (canonical; symlinked into bootstrap-workflow plugin)
├── scripts/                   # bootstrap.sh, doctor.sh (canonical; symlinked into bootstrap-workflow plugin)
├── plugins/                   # Plugin manifests. Symlinks in each plugin:
│                              #   plugins/<name>/skills/<name>      → ../../../skills/<name>
│                              #   plugins/bootstrap-workflow/scripts   → ../../scripts
│                              #   plugins/bootstrap-workflow/templates → ../../templates
└── .claude-plugin/            # marketplace.json
```

## License

MIT
