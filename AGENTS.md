# claude-kit — agent instructions

This is **not** a code project — it's a Claude Code starter kit. Skills, templates, and a bootstrap script.

## Repository layout

- **`skills/`** — canonical home for every skill. Flat: `skills/<name>/SKILL.md`. Edit skills HERE, never via the symlink under `plugins/`.
- **`docs/`** — public-facing docs: `stack.md`, `workflow.md`, `conventions.md`, `guardrails.md`
- **`templates/`** — drop-in artifacts copied into projects by `bootstrap.sh`. ALL local/gitignored: `CLAUDE.local.md`, `settings.local.json.tmpl` (contains `{{HOOKS_JSON}}` placeholder filled at write-time from `--hooks=`), `hooks/`, `gitignore-additions`. Symlinked into `plugins/bootstrap-workflow/templates`.
- **`plugins/`** — Claude Code plugins exposed via `.claude-plugin/marketplace.json`. Each plugin's `skills/<name>` is a **git-tracked symlink** (mode 120000) → `../../../skills/<name>`:
  - `bootstrap-workflow` — invokes `scripts/bootstrap.sh`. Plus two extra git-tracked symlinks so the plugin is self-sufficient over marketplace install: `plugins/bootstrap-workflow/scripts → ../../scripts` and `.../templates → ../../templates`. SKILL.md calls `${CLAUDE_PLUGIN_ROOT}/scripts/bootstrap.sh "$(pwd)"`. Target project does NOT need to clone claude-kit — symlinks ship with the plugin install.
  - `git-workflow` — single configurable commit/push/PR/sync skill
  - `session-handoff` — compact session into `.agent/handoffs/<ts>.md`
  - `setup-pre-commit` — team-shared husky + lint-staged setup
- **`scripts/`** — canonical home for `bootstrap.sh` (drops templates into a project) and `doctor.sh` (verify caveman/rtk/claude-mem/gh installed). Symlinked into `plugins/bootstrap-workflow/scripts`.
- **`.claude-plugin/marketplace.json`** — makes this repo installable as a Claude Code plugin source

Windows clones need `git config --global core.symlinks true`.

## Conventions

- Skills use YAML frontmatter with `disable-model-invocation: true` — explicit invoke only
- Skill names: kebab-case, match directory name
- Canonical skill file: `skills/<name>/SKILL.md`
- Each plugin: `plugins/<name>/.claude-plugin/plugin.json` + `plugins/<name>/skills/<name>` (symlink → `../../../skills/<name>`)
- All bootstrap drops are LOCAL (gitignored in target project) — overwrite is always safe
- `bootstrap.sh` is **flag-driven** and non-interactive when called with `--no-prompt`. Selection (`--features`, `--hooks`, `--brew-install`) is the gate — if a feature is on, it gets written; if off, it doesn't. No per-file overwrite prompts. The `bootstrap-workflow` skill collects the selection via `AskUserQuestion` and passes flags. `doctor.sh --json` feeds the brew-install picker.
- `setup-pre-commit` is the one exception — it COMMITS to the target repo (husky binds teammates)
- **pnpm-only enforcement** has two layers: `templates/hooks/block-non-pnpm.sh` (PreToolUse hook, gitignored, blocks `npm`/`yarn`/`bun` during Claude sessions) + `setup-pre-commit` (committed, enforces for teammates and CI). Both ship with claude-kit; don't add a third layer.
- **Stack awareness** — `detect_stack()` in `bootstrap.sh` + the equivalent `HAS_RUBY` / `HAS_NODE` switch in `doctor.sh` pick defaults from `Gemfile` / `package.json` / `Cargo.toml` / `pyproject.toml`. JS-only hooks (`block-non-pnpm`, `lint-on-edit`, `typecheck-on-stop`) are silently skipped on Ruby-only repos and the Ruby-only `lint-on-edit-rb` is skipped on JS-only repos; Ruby projects get `bundle exec rspec` / `standardrb` / `rubocop` defaults in `CLAUDE.local.md`. The `Hooks installed` block in `CLAUDE.local.md` is generated dynamically from `--hooks` so it never lies about what's wired up.

## When editing

- New skill → create `skills/<name>/SKILL.md` AND `ln -s ../../../skills/<name> plugins/<name>/skills/<name>` AND `git add` the symlink AND add row to `.claude-plugin/marketplace.json` AND update the README `📦 Plugins` list
- New plugin (reusing existing skill) → create `plugins/<name>/.claude-plugin/plugin.json` + symlink to the canonical skill + marketplace row
- New hook script → add to `templates/hooks/` AND to `templates/gitignore-additions` AND a one-line entry in the `build_hooks_json` function in `bootstrap.sh` (under the right event bucket: `pre` / `post` / `stop`) so it gets wired into `.claude/settings.local.json` AND to the `bootstrap.sh` hook copy loop AND as a multi-select option in `skills/bootstrap-workflow/SKILL.md` step 3 (with a sensible pre-check rule based on stack detection) AND a one-line entry in the `HOOKS_BLOCK` builder inside `bootstrap.sh` so it shows up under `Hooks installed` in `CLAUDE.local.md`. Declare which stacks the hook applies to and filter accordingly. (`templates/settings.local.json.tmpl` itself only holds the permissions block + a `{{HOOKS_JSON}}` placeholder — don't add hooks there.)
- New doc → surface in README `📚 More` if user-facing
- Touching `scripts/bootstrap.sh` or anything under `templates/` → no extra steps; the `plugins/bootstrap-workflow/{scripts,templates}` symlinks pick up changes automatically (don't duplicate files into the plugin dir)
- **Doc sync** — after any change, ask: does it shift what users see (`README.md`), what agents/contributors need to know (`AGENTS.md`), or the loop/conventions/bootstrap behaviour (`docs/`)? Update the affected file(s) in the same commit. New plugin → README `📦 Plugins`. New convention, new symlink, new enforcement layer → `AGENTS.md`. New skill in the loop or new bootstrap step → `docs/workflow.md` or related doc. Skip if change is purely internal (lockfile, prettier-only reformat, CI tweak with no behaviour change).

## CI

- `pnpm lint` — `agnix .` validates CLAUDE.md, SKILL.md, hooks, manifests (config: `.agnix.toml`, `templates/` excluded — placeholders, not real configs)
- `pnpm format` — `prettier --check` on md/json/yaml (config: `.prettierrc.json`, `proseWrap: preserve` so SKILL.md trigger tokens aren't rewrapped)
- `pnpm validate:manifests` — `claude plugin validate` on every `marketplace.json` + `plugin.json` plus version sync check between marketplace.json[].version and `<source>/.claude-plugin/plugin.json.version`
- `secrets-scan` — `trufflehog` (SHA-pinned) scans for verified/unknown leaked secrets; full-history checkout (`fetch-depth: 0`)
- Workflows in `.github/workflows/` run on `pull_request` + `push` to `main`; actions SHA-pinned, runner `ubuntu-latest`
