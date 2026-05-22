# dominikwozniak-skills — agent instructions

This is **not** a code project — it's a Claude Code starter kit. Skills, templates, and a bootstrap script.

## Repository layout

- **`docs/`** — public-facing docs: `stack.md`, `workflow.md`, `conventions.md`, `guardrails.md`
- **`templates/`** — drop-in artifacts copied into projects by `bootstrap.sh`. ALL local/gitignored: `CLAUDE.local.md`, `settings.local.json`, `hooks/`, `gitignore-additions`
- **`plugins/`** — Claude Code plugins exposed via `.claude-plugin/marketplace.json`:
  - `workflow-bootstrap` — invokes `scripts/bootstrap.sh`
  - `git-flow` — single configurable commit/push/PR/sync skill
  - `handoff` — compact session into `.agent/handoff-<ts>.md`
  - `setup-pre-commit` — team-shared husky + lint-staged setup
- **`scripts/`** — `bootstrap.sh` (drops templates into a project), `doctor.sh` (verify caveman/rtk/claude-mem/gh installed)
- **`.claude-plugin/marketplace.json`** — makes this repo installable as a Claude Code plugin source

## Conventions

- Skills use YAML frontmatter with `disable-model-invocation: true` — explicit invoke only
- Skill names: kebab-case, match directory name
- Each plugin: `plugins/<name>/.claude-plugin/plugin.json` + `plugins/<name>/skills/<name>/SKILL.md`
- All bootstrap drops are LOCAL (gitignored in target project) — overwrite is always safe
- `setup-pre-commit` is the one exception — it COMMITS to the target repo (husky binds teammates)

## When editing

- New plugin → add row to `.claude-plugin/marketplace.json` AND update README "Enable plugins" list
- New hook script → add to `templates/hooks/` AND to `templates/gitignore-additions` AND to the hook wiring in `templates/settings.local.json`
- New doc → link from README "What you get" if user-facing

## Reference patterns

- Plugin manifest schema: `../hub/.claude-plugin/marketplace.json`
- Skill frontmatter style: `../hub/skills/git/commit/SKILL.md`
- Hook patterns: `~/workspace/ahplus-web/.claude/hooks/`
- Guardrail block-list: upstream mattpocock/skills `git-guardrails-claude-code`
- Permissions ask-list: upstream lucas-barake/dotfiles `ai/canonical/claude.json`

## Not in scope

- `agnix` lint enforcement, `deno fmt` CI, secret scanning workflows — keep tooling minimal
- AGENTS.md symlink (skip for v1; add if codex compat needed)
- Memory/notes layer — that's `claude-mem`, not this repo
