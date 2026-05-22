---
name: session-handoff
description: >-
  Compact the current conversation into a handoff document so another agent
  (fresh Claude Code session, Codex, etc.) can continue the work. Trigger
  phrases: "session handoff", "handoff", "summarise for next session",
  "prepare context for another agent", "wrap up so someone can pick this up".
argument-hint: "What will the next session focus on?"
disable-model-invocation: true
---

# Session Handoff

Write a continuation document so the next agent — fresh CC session, Codex, or a teammate's agent — can resume without re-reading the whole transcript.

## Output location

Save to `.agent/handoffs/<YYYYMMDD-HHMM>.md` (project-local, gitignored). Create the directory if missing:

```bash
mkdir -p .agent/handoffs
```

Filename uses local time. Example: `.agent/handoffs/20260522-1430.md`.

## What to include

- **Goal** — one sentence: what we're trying to accomplish (use the user's argument if provided)
- **Current state** — what's been done, what's working, what's broken
- **Open questions** — decisions the next agent needs to make or surface to the user
- **Next steps** — ordered list of concrete actions to take next
- **Suggested skills** — Claude Code skills the next agent should invoke (e.g., `git-workflow`, `spec-driven-development`, `debugging-and-error-recovery`)
- **Pointers** — references to existing artifacts (specs, plans, ADRs, PRs, issues) by path or URL. Don't duplicate their content
- **Gotchas / context** — non-obvious things the next agent needs to know (env quirks, dependency versions, recent failures, etc.)

## What to leave out

- Don't re-summarise content already in committed files, PR descriptions, specs, plans, or ADRs. Reference them by path
- Redact secrets, API keys, PII, internal URLs that shouldn't be shared
- Skip narrative play-by-play of the conversation. Focus on actionable state

## Document template

```markdown
# Handoff — <YYYY-MM-DD HH:MM>

## Goal

<one sentence>

## Current state

- <what's done>
- <what's in progress>
- <what's blocked>

## Open questions

- <decision needed>

## Next steps

1. <action>
2. <action>
3. <action>

## Suggested skills

- `<skill-name>` — <why>

## Pointers

- spec: `.agent/spec-<name>.md`
- PR: <url or path>
- relevant files: `<path:line>`

## Gotchas

- <non-obvious context>
```

## After writing

Tell the user:

> Handoff saved to `.agent/handoffs/<filename>`. Open a new Claude Code session and run:
>
> ```
> Read the handoff at .agent/handoffs/<filename> and continue from there.
> ```
