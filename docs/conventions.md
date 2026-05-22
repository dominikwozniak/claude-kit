# Conventions

Defaults used by `git-workflow` and `bootstrap.sh`. Override per project by editing the matching section in `CLAUDE.local.md`.

## Commit format

```
[TICKET-XXX] type: description
```

If the branch doesn't encode a ticket, omit the prefix:

```
type: description
```

Rules:

- Imperative, lowercase, no period, ≤72 chars on subject
- Body explains *what* and *why* — the diff shows *how*. Skip for trivial changes
- **NO** `Co-Authored-By` trailer
- **NO** "Generated with Claude Code" or similar attribution footer
- One logical change per commit. When session work spans multiple concerns, split commits

## Git workflow

- **Rebase by default**: `git pull --rebase`, `git fetch origin && git rebase origin/main`
- Merge only when commits are already shared and rebasing would disrupt others
- Modern verbs: `git switch` / `git restore` over `git checkout`
- Stash with a message: `git stash push -m "<description>"` over bare `git stash`

## Branches

Loose. No enforcement.

Common patterns when a ticket exists (Linear, Jira):

```
XYZ-123-short-slug
XYZ-123/short-slug
```

`git-workflow` extracts the ticket key by regex `^[A-Z]+-\d+` if present and uses it in the commit and PR title.

## Pull requests

- **Title**: `[XYZ-123] type: description` if ticket present, else `type: description`
- **Body**: summary + test plan, generated from commits since base branch
- **NO** attribution footer
- **Created via**: `gh pr create` (never the web UI from the agent)

## Plans, specs, handoff docs

- Plans and specs land in `.agent/`
- Handoff docs land in `.agent/handoffs/`
- Everything in `.agent/` is gitignored by `bootstrap.sh` — never committed
- Delete the spec when the PR opens

## Project-level overrides

`CLAUDE.local.md` can contain a `## Git conventions` block. `git-workflow` reads it on each invocation and overrides the defaults above. Example:

```markdown
## Git conventions
- Default branch: develop
- Branch naming: feature/<ticket>-<slug>
- Commit format: type: description   <!-- skip ticket prefix even if branch encodes one -->
```
