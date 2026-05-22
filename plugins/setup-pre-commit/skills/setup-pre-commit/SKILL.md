---
name: setup-pre-commit
description: >-
  Use when adding pre-commit hooks to a JS/TS project. Detects package
  manager, installs husky + lint-staged + prettier, wires .husky/pre-commit
  to run lint-staged (and optionally typecheck + test). COMMITS to the repo
  — affects teammates. Trigger phrases: "set up pre-commit", "add husky",
  "configure lint-staged", "add commit-time formatting".
disable-model-invocation: true
---

# Setup Pre-Commit

One-time team-shared setup of `husky` + `lint-staged` + `prettier`. Adapted from mattpocock's `setup-pre-commit` + hub's `setup-hooks`.

This is **not** part of the bootstrap script — bootstrap drops local-only files. Pre-commit is committed to the repo and runs for every teammate. Invoke this skill explicitly.

## Workflow

### 1. Detect package manager

Check for the lockfile present in the repo root:

| Lockfile         | Manager  |
| ---------------- | -------- |
| `pnpm-lock.yaml` | pnpm     |
| `yarn.lock`      | yarn     |
| `bun.lockb`      | bun      |
| `package-lock.json` | npm   |

Default to `npm` if none present.

### 2. Detect tooling already in `package.json`

Look for: `eslint`, `biome`, `oxlint`, `prettier`, and `typecheck`/`test` scripts. Only configure what's already installed (don't install new linters as a side effect).

### 3. Install dependencies

```bash
# pnpm example
pnpm add -D husky lint-staged

# add prettier ONLY if not present
pnpm add -D prettier
```

### 4. Initialize husky

```bash
npx husky init   # v9+, no shebang needed in hook files
```

This creates `.husky/` and adds `"prepare": "husky"` to `package.json`.

### 5. Write `.lintstagedrc` (or `lint-staged` block in `package.json`)

Minimal version that adapts to detected tooling:

```json
{
  "*.{js,jsx,ts,tsx}": ["eslint --fix", "prettier --write"],
  "*.{json,css,scss,md}": "prettier --write"
}
```

If only Prettier is configured:

```json
{
  "*": "prettier --ignore-unknown --write"
}
```

### 6. Write `.husky/pre-commit`

```
npx lint-staged
```

Add `npm run typecheck` and `npm run test` lines ONLY if those scripts exist in `package.json` and the user wants the slower hook. Default: just `lint-staged` for speed.

### 7. Add `prepare` script (if not added by `husky init`)

```bash
npm pkg set scripts.prepare="husky || true"
```

The `|| true` prevents CI failures where husky isn't needed.

### 8. Smoke test

Stage a small change (touch a file, then commit). The hook runs lint-staged. If it passes, the setup is good.

### 9. Commit

```bash
git add .husky/ package.json package-lock.json .lintstagedrc 2>/dev/null || true
git add .husky/ package.json pnpm-lock.yaml .lintstagedrc 2>/dev/null || true
# (adapt to actual files changed)

git commit -m "chore: add husky + lint-staged pre-commit hook"
```

NO Co-Authored-By trailer, NO "Generated with Claude Code" footer (per project conventions).

## Non-JS projects

**Deno:** No husky. Native git hook:

```bash
mkdir -p .git/hooks
cat > .git/hooks/pre-commit <<'EOF'
#!/bin/sh
deno fmt --check && deno lint
EOF
chmod +x .git/hooks/pre-commit
```

**Python (Ruff):** Use the `pre-commit` framework — different tool, beyond this skill's scope.

## Notes

- `prettier --ignore-unknown` skips files Prettier can't parse (images, binaries)
- Husky v9+ doesn't need shebangs in hook files
- If you want to add typecheck/test to the pre-commit hook, warn the user — slower commits affect every teammate
