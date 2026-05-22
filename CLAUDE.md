# claude-kit — agent instructions

This is **not** a code project — it's a Claude Code starter kit. Skills, templates, and a bootstrap script.

## Repository layout

- **`skills/`** — canonical home for every skill. Flat: `skills/<name>/SKILL.md`. Edit skills HERE, never via the symlink under `plugins/`.
- **`docs/`** — public-facing docs: `stack.md`, `workflow.md`, `conventions.md`, `guardrails.md`
- **`templates/`** — drop-in artifacts copied into projects by `bootstrap.sh`. ALL local/gitignored: `CLAUDE.local.md`, `settings.local.json`, `hooks/`, `gitignore-additions`
- **`plugins/`** — Claude Code plugins exposed via `.claude-plugin/marketplace.json`. Each plugin's `skills/<name>` is a **git-tracked symlink** (mode 120000) → `../../../skills/<name>`:
  - `bootstrap-workflow` — invokes `scripts/bootstrap.sh`
  - `git-workflow` — single configurable commit/push/PR/sync skill
  - `session-handoff` — compact session into `.agent/handoffs/<ts>.md`
  - `setup-pre-commit` — team-shared husky + lint-staged setup
- **`scripts/`** — `bootstrap.sh` (drops templates into a project), `doctor.sh` (verify caveman/rtk/claude-mem/gh installed)
- **`.claude-plugin/marketplace.json`** — makes this repo installable as a Claude Code plugin source

## Conventions

- Skills use YAML frontmatter with `disable-model-invocation: true` — explicit invoke only
- Skill names: kebab-case, match directory name
- Canonical skill file: `skills/<name>/SKILL.md`
- Each plugin: `plugins/<name>/.claude-plugin/plugin.json` + `plugins/<name>/skills/<name>` (symlink → `../../../skills/<name>`)
- All bootstrap drops are LOCAL (gitignored in target project) — overwrite is always safe
- `setup-pre-commit` is the one exception — it COMMITS to the target repo (husky binds teammates)

## When editing

- New skill → create `skills/<name>/SKILL.md` AND `ln -s ../../../skills/<name> plugins/<name>/skills/<name>` AND `git add` the symlink AND add row to `.claude-plugin/marketplace.json` AND update README plugins table
- New plugin (reusing existing skill) → create `plugins/<name>/.claude-plugin/plugin.json` + symlink to the canonical skill + marketplace row
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
