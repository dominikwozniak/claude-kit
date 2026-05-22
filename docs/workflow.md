# Workflow

This kit uses [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) as the daily loop. We don't reimplement it — we wire it into project bootstrap and add a few conventions on top.

## The loop

```
/spec  → write a structured spec for the change
/plan  → break it into ordered, verifiable tasks
/build → implement incrementally with tests
```

The triplet above is the daily working set. The full agent-skills lifecycle also ships `/test`, `/review`, and `/ship` — reach for them when the change warrants more rigour (new public API, security-sensitive code, production rollout).

## Conventions

- **Where artifacts land**: `.agent/` at the repo root. `bootstrap.sh` adds `.agent/` to `.gitignore` so nothing leaks into PRs.
- **Spec lifetime**: treat specs as a planning artifact, not a deliverable. Delete the spec when you open the PR — code, tests, and commit history are the durable artifacts.
- **When to skip the loop**: trivial changes (typos, single-line fixes, renames). The loop's value is forcing clarity for non-trivial work.
- **When to use it manually anyway**: even without running `/spec`, the questions the spec asks (problem, scope, acceptance criteria) are good mental hygiene.

## Layered with session-handoff

When a session gets long, or you want a different agent to continue:

```
/session-handoff "What the next session will focus on"
```

Writes `.agent/handoffs/<YYYYMMDD-HHMM>.md` — a compact continuation document in its own subfolder. Pick it up in a fresh Claude Code session or hand it to Codex.

## Layered with claude-mem

`claude-mem` auto-injects context from past sessions. Use `mem-search` explicitly when you suspect "we already solved this" — saves the agent from rebuilding context from scratch.
