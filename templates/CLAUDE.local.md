# {{PROJECT_NAME}} — local agent memory

Personal Claude Code memory for this project. Gitignored. Bootstrap dropped this file — edit freely.

## Workflow

- Loop: `/spec → /plan → /build` via [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills)
- Plans and specs land in `.agent/` (gitignored). **NEVER** commit them.
- Handoff docs land in `.agent/handoffs/<YYYYMMDD-HHMM>.md`. Use `/session-handoff` to create one.
- Delete the spec when the PR opens.

## Tools active in this session

- **caveman** — response compression. Code, commits, security warnings stay normal.
- **rtk** — Bash output filter, rewrites commands transparently. Don't call `rtk` manually.
- **claude-mem** — cross-session memory. Use `mem-search` when you suspect "we already solved this".
- **gh CLI** — preferred over MCP for GitHub ops.
- Linear / Atlassian / Notion — via MCP **if installed** for this project. Check `claude mcp list`; drop the bullet if not used.
- Sentry / Playwright — via CLI when needed.

## Git conventions

Read by the `git-workflow` skill. Overrides global defaults.

- **Commit format**: `[TICKET-XXX] type: description` if branch encodes a ticket, else `type: description`
  - Follows [Conventional Commits 1.0](https://www.conventionalcommits.org/en/v1.0.0/)
  - Examples:
    - `[ABC-123] feat: add password reset endpoint`
    - `[ABC-124] fix: handle null token in middleware`
    - `refactor: extract auth helpers into lib/auth.ts`
- **Default branch**: {{DEFAULT_BRANCH}}
- **Branch naming**: loose. Common when ticket exists: `XYZ-123-short-slug` or `XYZ-123/short-slug`. No enforcement.
- **PR title**: same format as commit subject.
- **NO** `Co-Authored-By` trailer. **NO** "Generated with Claude Code" footer.
- **Rebase by default**: `git pull --rebase`, `git fetch origin && git rebase origin/{{DEFAULT_BRANCH}}`
- **Signed commits**: this repo expects signed commits. Verify with `git config --global --get commit.gpgsign` (must be `true`). If unsigned, use `git commit -S` per commit or set `git config --global commit.gpgsign true` once.
- **Modern verbs**: `git switch` / `git restore` over `git checkout`
- **One logical change per commit**. Split when session work spans multiple concerns.
- **Stash**: `git stash push -m "<description>"` over bare `git stash`.

## Project specifics

- **Stack**: {{STACK}}
- **Test command**: {{TEST_COMMAND}}
- **Lint command**: {{LINT_COMMAND}}
- **Typecheck command**: {{TYPECHECK_COMMAND}}
- **Domain**: {{DOMAIN_BLURB}}
- **Key directories**: {{KEY_DIRS}}
- **Deployment target**: {{DEPLOY_TARGET}}
- **Gotchas**: {{GOTCHAS}}

## Hooks installed

{{HOOKS_INSTALLED}}

Hook scripts live in `.claude/hooks/` and are gitignored.

## Keep this file current

This file is the source of truth for the agent _and_ the hooks. If any of these change, update the matching line here in the same commit:

- Test / lint / typecheck command in your toolchain (`Gemfile`, `package.json`, …) → update the `Project specifics` block (hooks read those names)
- Default branch renamed → update `Git conventions` (`git-workflow` reads it)
- Stack, key directories, deployment target shifts → update `Project specifics`
- New tool installed (MCP server, CLI) or one removed → update `Tools active in this session`
- New hook wired in `.claude/settings.local.json` → add a line under `Hooks installed`

Stale placeholders silently break the linter, typecheck, and PR/commit flow.
