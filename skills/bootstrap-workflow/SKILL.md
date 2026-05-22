---
name: bootstrap-workflow
description: >-
  Use when applying the claude-kit setup to a new project — drops
  CLAUDE.local.md, .claude/settings.local.json, three hook scripts, and updates
  .gitignore. All artifacts are local/gitignored. Trigger phrases: "bootstrap
  this project", "set up workflow", "apply claude-kit".
disable-model-invocation: true
---

# Workflow Bootstrap

Apply the claude-kit personal setup to the current project. Everything dropped is gitignored — safe to run repeatedly.

## What gets installed

- `CLAUDE.local.md` (root, gitignored) — workflow + git conventions + tool list
- `.claude/settings.local.json` (gitignored) — permissions ask-list + three hooks wired
- `.claude/hooks/block-dangerous-git.sh` (gitignored) — PreToolUse guardrail
- `.claude/hooks/lint-on-edit.sh` (gitignored) — PostToolUse linter
- `.claude/hooks/typecheck-on-stop.sh` (gitignored) — Stop hook typecheck
- `.gitignore` — append `.agent/`, `CLAUDE.local.md`, `settings.local.json`, hook scripts (idempotent, marker-fenced)

## Workflow

### 1. Run bootstrap

Claude Code sets `${CLAUDE_PLUGIN_ROOT}` to this plugin's install directory. The script and templates ship with the plugin via git-tracked symlinks, so no separate clone is needed.

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/bootstrap.sh" "$(pwd)"
```

If `${CLAUDE_PLUGIN_ROOT}` is empty (skill invoked outside Claude Code), fall back to the local repo checkout path and ask the user.

The script:

1. Runs `doctor.sh` (warn-only check for caveman, rtk, claude-mem, gh, etc.)
2. Confirms the target is a git repo
3. Creates `.claude/hooks/` and `.agent/handoffs/`
4. Prompts before overwriting any existing file
5. Fills `CLAUDE.local.md` placeholders by auto-detecting `package.json` scripts + git default branch (user confirms each)
6. Appends to `.gitignore` between marker comments

### 2. Confirm with the user

Show the resulting `CLAUDE.local.md`. Ask if any conventions need adjusting (commit format, branch naming, etc.).

### 3. Suggest companion plugins

Tell the user to:

```
/plugin marketplace add github:dominikwozniak/claude-kit
/plugin install git-workflow
/plugin install session-handoff
```

…and to ensure `agent-skills` (addyosmani), `caveman`, `claude-mem` are enabled in `~/.claude/settings.json`.

## Notes

- Re-running the script is safe — every prompt asks before overwrite, `.gitignore` block is idempotent
- The script never touches files that aren't local/gitignored — no teammate impact
- If the user wants team-shared pre-commit hooks (husky + lint-staged), point them to the `setup-pre-commit` skill — separate concern
