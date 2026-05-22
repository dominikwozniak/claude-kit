# claude-kit — agent instructions

This is **not** a code project — it's a Claude Code starter kit. Skills, templates, and a bootstrap script.

## Repository layout

- **`skills/`** — canonical home for every skill. Flat: `skills/<name>/SKILL.md`. Edit skills HERE, never via the symlink under `plugins/`.
- **`docs/`** — public-facing docs: `stack.md`, `workflow.md`, `conventions.md`, `guardrails.md`
- **`templates/`** — drop-in artifacts copied into projects by `bootstrap.sh`. ALL local/gitignored: `CLAUDE.local.md`, `settings.local.json`, `hooks/`, `gitignore-additions`. Symlinked into `plugins/bootstrap-workflow/templates`.
- **`plugins/`** — Claude Code plugins exposed via `.claude-plugin/marketplace.json`. Each plugin's `skills/<name>` is a **git-tracked symlink** (mode 120000) → `../../../skills/<name>`:
  - `bootstrap-workflow` — invokes `scripts/bootstrap.sh`. Plus two extra git-tracked symlinks so the plugin is self-sufficient over marketplace install: `plugins/bootstrap-workflow/scripts → ../../scripts` and `.../templates → ../../templates`. SKILL.md calls `${CLAUDE_PLUGIN_ROOT}/scripts/bootstrap.sh "$(pwd)"`. Target project does NOT need to clone claude-kit — symlinks ship with the plugin install.
  - `git-workflow` — single configurable commit/push/PR/sync skill
  - `session-handoff` — compact session into `.agent/handoffs/<ts>.md`
  - `setup-pre-commit` — team-shared husky + lint-staged setup
- **`scripts/`** — canonical home for `bootstrap.sh` (drops templates into a project) and `doctor.sh` (verify caveman/rtk/claude-mem/gh installed). Symlinked into `plugins/bootstrap-workflow/scripts`.
- **`.claude-plugin/marketplace.json`** — makes this repo installable as a Claude Code plugin source

## Conventions

- Skills use YAML frontmatter with `disable-model-invocation: true` — explicit invoke only
- Skill names: kebab-case, match directory name
- Canonical skill file: `skills/<name>/SKILL.md`
- Each plugin: `plugins/<name>/.claude-plugin/plugin.json` + `plugins/<name>/skills/<name>` (symlink → `../../../skills/<name>`)
- All bootstrap drops are LOCAL (gitignored in target project) — overwrite is always safe
- `setup-pre-commit` is the one exception — it COMMITS to the target repo (husky binds teammates)
- **pnpm-only enforcement** has two layers: `templates/hooks/block-non-pnpm.sh` (PreToolUse hook, gitignored, blocks `npm`/`yarn`/`bun` during Claude sessions) + `setup-pre-commit` (committed, enforces for teammates and CI). Both ship with claude-kit; don't add a third layer.

## When editing

- New skill → create `skills/<name>/SKILL.md` AND `ln -s ../../../skills/<name> plugins/<name>/skills/<name>` AND `git add` the symlink AND add row to `.claude-plugin/marketplace.json` AND update README plugins table
- New plugin (reusing existing skill) → create `plugins/<name>/.claude-plugin/plugin.json` + symlink to the canonical skill + marketplace row
- New hook script → add to `templates/hooks/` AND to `templates/gitignore-additions` AND to the hook wiring in `templates/settings.local.json`
- New doc → link from README "What you get" if user-facing
- Touching `scripts/bootstrap.sh` or anything under `templates/` → no extra steps; the `plugins/bootstrap-workflow/{scripts,templates}` symlinks pick up changes automatically (don't duplicate files into the plugin dir)
- **Doc sync** — after any change, ask: does it shift what users see (`README.md`), what agents need to know (`CLAUDE.md`), or how the daily loop/bootstrap behaves (`docs/`)? Update the affected file(s) in the same commit. New plugin / pain narrative → README. New convention, new symlink, new enforcement layer → CLAUDE.md. New skill in the loop or new bootstrap step → `docs/workflow.md` or related doc. Skip if change is purely internal (lockfile, prettier-only reformat, CI tweak with no behaviour change).

## Reference patterns

- Plugin manifest schema: `../hub/.claude-plugin/marketplace.json`
- Skill frontmatter style: `../hub/skills/git/commit/SKILL.md`
- Hook patterns: `~/workspace/ahplus-web/.claude/hooks/`
- Guardrail block-list: upstream mattpocock/skills `git-guardrails-claude-code`
- Permissions ask-list: upstream lucas-barake/dotfiles `ai/canonical/claude.json`

## CI

- `pnpm lint` — `agnix .` validates CLAUDE.md, SKILL.md, hooks, manifests (config: `.agnix.toml`, `templates/` excluded — placeholders, not real configs)
- `pnpm format` — `prettier --check` on md/json/yaml (config: `.prettierrc.json`, `proseWrap: preserve` so SKILL.md trigger tokens aren't rewrapped)
- `pnpm validate:manifests` — `claude plugin validate` on every `marketplace.json` + `plugin.json` plus version sync check between marketplace.json[].version and `<source>/.claude-plugin/plugin.json.version`
- Workflows in `.github/workflows/` run all three on `pull_request` + `push` to `main`; actions SHA-pinned, runner `ubuntu-latest`

## Not in scope

- Secret scanning workflows — `AirHelp/ai-hub` and `byarcadia-app/hub` use reusable workflows from private orgs; standalone gitleaks/trufflehog can be added later
- `sync-public-skills` — no public skills to sync; add if upstream sources appear
- AGENTS.md symlink (skip for v1; add if codex compat needed)
- Memory/notes layer — that's `claude-mem`, not this repo
