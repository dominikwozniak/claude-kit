# Guardrails

What `bootstrap.sh` wires into `.claude/settings.local.json` to keep the agent from doing irreversible damage.

## Hard blocks (`PreToolUse` Bash hook)

`templates/hooks/block-dangerous-git.sh` blocks these patterns outright. Agent sees stderr and self-corrects.

| Pattern              | Why                                                            |
| -------------------- | -------------------------------------------------------------- |
| `git push --force`   | Rewrites shared history; lost commits are unrecoverable        |
| `git push -f`        | Same as above, short form                                      |
| `git reset --hard`   | Discards uncommitted work without recovery                     |
| `git clean -f`       | Deletes untracked files permanently                            |
| `git clean -fd`      | Same, with directories                                         |
| `git branch -D`      | Force-deletes a branch even if unmerged                        |
| `git checkout .`     | Discards all unstaged changes                                  |
| `git restore .`      | Same as above (modern syntax)                                  |

To extend: edit `templates/hooks/block-dangerous-git.sh` and append patterns to `DANGEROUS_PATTERNS`.

## Soft asks (`permissions.ask`)

Less destructive but high-blast-radius. Claude Code prompts you before running.

```jsonc
"ask": [
  "Bash(rm *)", "Bash(rm -*)",
  "Bash(sudo *)",
  "Bash(gh repo delete *)",
  "Bash(gh pr close *)",
  "Bash(gh issue close *)",
  "Bash(gh release delete *)",
  "Bash(git push --force*)",
  "Bash(git push -f*)"
]
```

`git push` (without `--force`) is NOT in the ask-list — it's a normal daily op. The agent prompts you anyway when the branch is `main` (Claude Code's built-in safety).

## Why this split

- **Block** = the agent should not be able to do this even if you say yes mid-task. Catastrophic + agent has no business proposing it.
- **Ask** = you might genuinely want it. Worth a one-tap confirmation.

## Adding your own

Edit `templates/settings.local.json` and `templates/hooks/block-dangerous-git.sh` in this repo, then re-run `bootstrap.sh` on your target project.
