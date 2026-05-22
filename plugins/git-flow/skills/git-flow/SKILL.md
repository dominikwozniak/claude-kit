---
name: git-flow
description: >-
  Use for any git operation in this project — commit, push, PR, sync, branch,
  stash. Reads conventions from CLAUDE.local.md; falls back to defaults.
  Trigger phrases: "commit", "push", "open PR", "create pull request", "sync
  with main", "stash my work", "new branch".
disable-model-invocation: true
---

# git-flow

One skill, all git ops. Configurable via `CLAUDE.local.md`.

## Step 0: read project conventions

Before any operation, read `CLAUDE.local.md` (repo root) if it exists. Look for a `## Git conventions` block. Use those values to override the defaults below. Examples of overridable values: commit format, default branch, branch naming, Co-Authored-By inclusion, PR title format.

If no `CLAUDE.local.md` or no `## Git conventions` block, use the defaults documented in each section.

## Operations

### commit

**Defaults:**

- Format: `[TICKET-XXX] type: description` if current branch matches `^[A-Z]+-\d+`, else `type: description`
- Subject: imperative, lowercase, no period, ≤72 chars
- Body: explain what + why for non-trivial changes; skip for trivial
- **NO** `Co-Authored-By` trailer
- **NO** "Generated with Claude Code" or any attribution footer
- One logical change per commit — when session work spans multiple concerns, split

**Workflow:**

1. `git status --short` — see all changes
2. Classify files: session work (created/edited this conversation) vs pre-existing
3. Stage session work by name: `git add path1 path2`. Never `git add .` or `git add -A` unless explicitly asked
4. Sensitive files (`.env`, credentials, API keys): warn and exclude
5. `git diff --staged` — review
6. Extract ticket key from branch name: `git branch --show-current | grep -oE '^[A-Z]+-[0-9]+'`
7. Generate subject. If ticket key found, prefix `[KEY] `
8. Commit via heredoc:

```bash
git commit -m "$(cat <<'EOF'
[XYZ-123] type: imperative subject

Optional body. What changed and why.
EOF
)"
```

9. `git log --oneline -1` — confirm

### push

**Defaults:**

- Plain `git push` for regular branches
- Block `--force` (handled by `.claude/hooks/block-dangerous-git.sh` if installed; otherwise warn and refuse)
- Block push to `main`/`master`/`develop` without explicit confirmation

**Workflow:**

1. Check current branch: `git branch --show-current`
2. If branch is `main`/`master`/`develop`, ask for explicit confirmation
3. Check upstream: `git rev-parse --abbrev-ref @{u} 2>/dev/null`
4. If no upstream, `git push -u origin "$(git branch --show-current)"`. Else `git push`
5. Report result

### PR (`open PR`, `create pull request`)

**Defaults:**

- Title: same format as commit subject (`[TICKET-XXX] type: description`)
- Body: summary + test plan from commits since base branch
- **NO** "Generated with Claude Code" footer
- Created via `gh pr create` — never the web UI

**Workflow:**

1. Push branch first if not pushed (see push section)
2. Determine base branch (default from CLAUDE.local.md or `git symbolic-ref --short refs/remotes/origin/HEAD`)
3. Generate body:

```markdown
## Summary

- <bullet from each commit>

## Test plan

- [ ] <test item>
- [ ] <test item>
```

4. Title format: `[KEY] type: description` if ticket present in branch, else `type: description`
5. Create:

```bash
gh pr create --title "..." --body "$(cat <<'EOF'
## Summary
...
## Test plan
...
EOF
)"
```

6. Print PR URL

### sync (`sync with main`, `rebase`)

**Defaults:**

- Rebase, not merge
- Refuse if working tree dirty — ask user to commit or stash

**Workflow:**

```bash
git fetch origin
git rebase origin/<default-branch>
```

If conflicts: report them, do NOT auto-resolve, let user decide.

### branch (`new branch`, `switch branch`)

**Defaults:**

- Use `git switch -c` (not `git checkout -b`)
- Branch name: prompt for ticket key + slug if not provided

**Workflow:**

```bash
git switch -c <ticket>-<slug>
# or
git switch -c <ticket>/<slug>
```

### stash (`stash my work`)

**Defaults:**

- Always with a message: `git stash push -m "..."`
- Never bare `git stash`

**Workflow:**

```bash
git stash push -m "<short description of what's being saved>"
```

## Notes

- All defaults assume `block-dangerous-git.sh` hook is installed via `workflow-bootstrap`. If absent, manually refuse the same patterns (force-push, hard-reset, etc.).
- If the project has a PR template at `.github/PULL_REQUEST_TEMPLATE.md`, use it as the body skeleton instead of the generic summary/test-plan format above.
