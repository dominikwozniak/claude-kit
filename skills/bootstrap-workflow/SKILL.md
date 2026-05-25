---
name: bootstrap-workflow
description: >-
  Use when applying the claude-kit setup to a new project — drops
  CLAUDE.local.md, .claude/settings.local.json, hook scripts, and updates
  .gitignore. À la carte picker via AskUserQuestion: choose artifacts,
  pick hooks, optionally brew-install missing deps. All artifacts are
  local/gitignored. Trigger phrases: "bootstrap this project", "set up
  workflow", "apply claude-kit".
disable-model-invocation: true
---

# Workflow Bootstrap

Apply the claude-kit personal setup to the current project. Everything dropped is gitignored — safe to run repeatedly. Selection is the gate: only what you pick gets written.

## What can be installed

- `CLAUDE.local.md` (root, gitignored) — workflow + git conventions + tool list
- `.claude/settings.local.json` (gitignored) — permissions ask-list + hook wiring
- `.claude/hooks/block-dangerous-git.sh` — PreToolUse guard, blocks force-push / hard-reset / etc.
- `.claude/hooks/block-non-pnpm.sh` — PreToolUse guard, blocks npm / yarn / bun
- `.claude/hooks/lint-on-edit.sh` — PostToolUse, lints edited TS/JS files
- `.claude/hooks/typecheck-on-stop.sh` — Stop hook, typechecks on TS file changes
- `.gitignore` — appends idempotent block fencing the above

## Workflow

Follow this procedure in order. Each step has a single purpose.

### 1. Detect repo characteristics

Read just enough of the target project to pre-check the picker boxes intelligently and pick stack-aware defaults:

```bash
test -f package.json && echo "has-pkg"
test -f tsconfig.json && echo "has-tsconfig"
test -f Gemfile && echo "has-gemfile"
jq -r '.scripts.lint // empty' package.json 2>/dev/null
grep -q 'gem .standard.' Gemfile 2>/dev/null && echo "has-standardrb"
grep -q 'gem .rubocop' Gemfile 2>/dev/null && echo "has-rubocop"
grep -q 'gem .rspec'   Gemfile 2>/dev/null && echo "has-rspec"
```

(The exact Gemfile detection regex lives in `bootstrap.sh`; the snippet above is illustrative — agents can read the script for the precise quoting.)

Use the results to decide pre-check defaults for step 3:

- `block-dangerous-git.sh` — always pre-check (stack-neutral)
- `block-non-pnpm.sh` — pre-check only if `package.json` exists. Hide entirely on Ruby-only repos.
- `lint-on-edit.sh` — pre-check only if `package.json` has a `lint` script. Hide on Ruby-only repos (regex matches JS extensions).
- `typecheck-on-stop.sh` — pre-check only if `tsconfig.json` exists. Hide on Ruby-only repos.

### 2. Run doctor.sh for missing deps

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/doctor.sh" --json
```

Parse with `jq`. The script returns `{missing, optional_missing, plugin_missing, marketplace_missing}`. Use `optional_missing` to populate the brew-install question (step 3, question 3). Skip that question if the array is empty or `brew` is not on PATH.

### 3. Ask the user — picker via AskUserQuestion

Three questions (skip question 2 if answer to Q1 doesn't include `settings`; skip question 3 if nothing brew-installable to offer):

**Question 1 — Artifacts to drop (multi-select):**

- `CLAUDE.local.md` (recommended)
- `.claude/settings.local.json` (recommended — hooks below need it)
- `.gitignore additions` (recommended)

**Question 2 — Hooks to install (multi-select, only if `settings` selected above):**

- `block-dangerous-git` — universal git guardrail (always offered)
- `block-non-pnpm` — JS/TS only (skip on Ruby-only repos)
- `lint-on-edit` — only useful with a lint script (skip on Ruby-only repos)
- `typecheck-on-stop` — TypeScript only (skip on Ruby-only repos)

Use the detection results from step 1 as the default-checked set. Filter out JS-only hooks when `package.json` is absent — on a pure Rails repo, only `block-dangerous-git` is offered.

If filtering leaves **fewer than 2 options**, do not call `AskUserQuestion` with a multi-select — that violates the tool's `minItems: 2` validation. Instead, ask a single Yes/No question naming the lone remaining hook (e.g. _"Install `block-dangerous-git` hook?"_) with options `Yes (recommended)` / `No`. Map `Yes` → include that hook in `--hooks=`; `No` → pass `--hooks=` empty. Q1 (artifacts) always has 3 fixed options, so this fallback only ever applies to Q2 and Q3.

**Question 3 — Missing deps to brew install (multi-select, only when applicable):**

Render the `optional_missing` array from doctor.sh as options. Pre-check none — let the user opt in.

If `optional_missing` has exactly one entry, fall back to a Yes/No prompt naming that tool (e.g. _"Install `rtk` via brew?"_) with `Yes` / `No (skip)` — same `minItems: 2` reason as Q2. Skip the question entirely when the array is empty or `brew` is not on PATH.

### 4. Collect CLAUDE.local.md placeholder values

Only if `CLAUDE.local.md` was selected. Use a single AskUserQuestion round with the defaults pre-filled from auto-detection. Suggested defaults:

- `project-name` → `basename "$(pwd)"`
- `default-branch` → `git symbolic-ref --short refs/remotes/origin/HEAD | sed 's@^origin/@@'` or `git config --get init.defaultBranch` or `main`
- `stack` → detect from `package.json` / `tsconfig.json` / `Cargo.toml` / `pyproject.toml` / `Gemfile`
- `test-cmd`, `lint-cmd`, `typecheck-cmd` — stack-dependent:
  - **Node / TS**: `jq -r '.scripts.<name>'` of `package.json`, falling back to `pnpm <name>`.
  - **Ruby**: `bundle exec rspec` (or `bin/rails test` if no rspec gem) for test, `bundle exec standardrb --fix` or `bundle exec rubocop -A` based on `Gemfile` for lint, empty (renders as `_(n/a)_`) for typecheck.
  - **Other / unknown**: leave empty so the user fills them in.
- `domain`, `key-dirs`, `deploy`, `gotchas` → empty (user fills later)

Bootstrap.sh handles all of the above auto-detection — you only need to pass the flags the user explicitly overrides.

### 5. Invoke bootstrap.sh with flags

Construct a single non-interactive call:

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/bootstrap.sh" "$(pwd)" \
  --features=claude-md,settings,gitignore \
  --hooks=block-dangerous-git,lint-on-edit \
  --brew-install=rtk \
  --project-name="fancy" \
  --default-branch="main" \
  --stack="TypeScript / Node" \
  --test-cmd="pnpm test" \
  --lint-cmd="pnpm lint" \
  --typecheck-cmd="pnpm typecheck" \
  --no-prompt
```

Omit `--brew-install=` and any placeholder flag the user didn't fill. `--no-prompt` is mandatory from the skill path — Claude's Bash tool has no TTY, so the script must run unattended.

If `${CLAUDE_PLUGIN_ROOT}` is empty (skill invoked outside Claude Code), fall back to the local repo checkout path and ask the user.

### 6. Confirm with the user

Show the resulting `CLAUDE.local.md` (if installed). Ask if any conventions need adjusting (commit format, branch naming, etc.).

### 7. Suggest companion plugins

Tell the user to:

```
/plugin marketplace add github:dominikwozniak/claude-kit
/plugin install git-workflow
/plugin install session-handoff
```

…and to ensure `agent-skills` (addyosmani), `caveman`, `claude-mem` are enabled in `~/.claude/settings.json`.

## Notes

- Re-running is safe — the `.gitignore` block is marker-fenced and idempotent; `settings.local.json` is overwritten wholesale; hook files are overwritten.
- De-selecting a hook in a later run does **not** remove the previously-installed file. Delete it manually if you want it gone.
- The script never touches files that aren't local/gitignored — no teammate impact.
- For team-shared pre-commit hooks (husky + lint-staged), use the `setup-pre-commit` skill — separate concern.
- Direct invocation outside Claude is still supported: `scripts/bootstrap.sh <dir>` without `--no-prompt` falls back to `read </dev/tty` prompts for any unset placeholder. Flags still work, e.g. `scripts/bootstrap.sh /tmp/foo --features=claude-md --hooks=`.
