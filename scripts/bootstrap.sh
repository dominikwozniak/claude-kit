#!/usr/bin/env bash
# Drop dominikwozniak-skills templates into a target project.
# Everything written is local/gitignored — safe to overwrite.
#
# Usage: bootstrap.sh <target-dir>

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATES="$REPO_ROOT/templates"

green() { printf "\033[32m%s\033[0m\n" "$1"; }
yellow() { printf "\033[33m%s\033[0m\n" "$1"; }
red() { printf "\033[31m%s\033[0m\n" "$1"; }

if [[ $# -ne 1 ]]; then
  red "Usage: $0 <target-dir>"
  exit 1
fi

TARGET="$(cd "$1" 2>/dev/null && pwd)" || {
  red "Target directory not found: $1"
  exit 1
}

if [[ ! -d "$TARGET/.git" ]]; then
  red "$TARGET is not a git repository. Run 'git init' first."
  exit 1
fi

echo "Bootstrapping dominikwozniak-skills into: $TARGET"
echo

# Optional doctor — warn but continue.
if [[ -x "$SCRIPT_DIR/doctor.sh" ]]; then
  yellow "Running doctor.sh (warn-only)…"
  "$SCRIPT_DIR/doctor.sh" || yellow "doctor.sh reported missing tools — continuing anyway."
  echo
fi

cd "$TARGET"
mkdir -p .claude/hooks .agent/handoffs

# --- Helpers ---------------------------------------------------------------

prompt_overwrite() {
  local file="$1"
  if [[ -f "$file" ]]; then
    yellow "$file already exists."
    read -r -p "  Overwrite? [y/N] " yn </dev/tty
    [[ "$yn" =~ ^[Yy]$ ]]
  else
    true
  fi
}

detect_default_branch() {
  local b
  b=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's@^origin/@@')
  [[ -z "$b" ]] && b=$(git config --get init.defaultBranch 2>/dev/null)
  [[ -z "$b" ]] && b="main"
  echo "$b"
}

read_pkg_script() {
  local script="$1"
  command -v jq >/dev/null || { echo ""; return; }
  [[ -f "package.json" ]] || { echo ""; return; }
  jq -r --arg s "$script" '.scripts[$s] // empty' package.json 2>/dev/null || echo ""
}

detect_stack() {
  if [[ -f "package.json" ]]; then
    if [[ -f "tsconfig.json" ]]; then echo "TypeScript / Node"
    else echo "JavaScript / Node"
    fi
  elif [[ -f "deno.json" || -f "deno.jsonc" ]]; then echo "Deno / TypeScript"
  elif [[ -f "Cargo.toml" ]]; then echo "Rust"
  elif [[ -f "pyproject.toml" || -f "requirements.txt" ]]; then echo "Python"
  elif [[ -f "Gemfile" ]]; then echo "Ruby"
  else echo "unknown"
  fi
}

prompt_or_default() {
  local label="$1" suggestion="$2" reply
  read -r -p "  $label [$suggestion]: " reply </dev/tty
  echo "${reply:-$suggestion}"
}

# --- 1. CLAUDE.local.md (root) --------------------------------------------

if prompt_overwrite "CLAUDE.local.md"; then
  PROJECT_NAME="$(basename "$TARGET")"
  DEFAULT_BRANCH="$(detect_default_branch)"
  STACK="$(detect_stack)"
  TEST_CMD="$(read_pkg_script test)"
  LINT_CMD="$(read_pkg_script lint)"
  TYPECHECK_CMD="$(read_pkg_script typecheck)"

  echo
  echo "Confirm project specifics (press Enter to accept suggestion):"
  PROJECT_NAME=$(prompt_or_default "Project name" "$PROJECT_NAME")
  DEFAULT_BRANCH=$(prompt_or_default "Default branch" "$DEFAULT_BRANCH")
  STACK=$(prompt_or_default "Stack" "$STACK")
  TEST_CMD=$(prompt_or_default "Test command" "${TEST_CMD:-npm test}")
  LINT_CMD=$(prompt_or_default "Lint command" "${LINT_CMD:-npm run lint}")
  TYPECHECK_CMD=$(prompt_or_default "Typecheck command" "${TYPECHECK_CMD:-npm run typecheck}")

  sed \
    -e "s|{{PROJECT_NAME}}|$PROJECT_NAME|g" \
    -e "s|{{DEFAULT_BRANCH}}|$DEFAULT_BRANCH|g" \
    -e "s|{{STACK}}|$STACK|g" \
    -e "s|{{TEST_COMMAND}}|$TEST_CMD|g" \
    -e "s|{{LINT_COMMAND}}|$LINT_CMD|g" \
    -e "s|{{TYPECHECK_COMMAND}}|$TYPECHECK_CMD|g" \
    "$TEMPLATES/CLAUDE.local.md" > CLAUDE.local.md
  green "✓ CLAUDE.local.md (root, gitignored)"
else
  yellow "↷ skipped CLAUDE.local.md"
fi

# --- 2. .claude/settings.local.json ---------------------------------------

if prompt_overwrite ".claude/settings.local.json"; then
  cp "$TEMPLATES/settings.local.json" .claude/settings.local.json
  green "✓ .claude/settings.local.json"
else
  yellow "↷ skipped .claude/settings.local.json"
fi

# --- 3. Hook scripts ------------------------------------------------------

for hook in block-dangerous-git.sh lint-on-edit.sh typecheck-on-stop.sh; do
  if prompt_overwrite ".claude/hooks/$hook"; then
    cp "$TEMPLATES/hooks/$hook" ".claude/hooks/$hook"
    chmod +x ".claude/hooks/$hook"
    green "✓ .claude/hooks/$hook"
  else
    yellow "↷ skipped .claude/hooks/$hook"
  fi
done

# --- 4. .gitignore additions (idempotent via marker) ----------------------

MARKER_BEGIN="# dominikwozniak-skills bootstrap (BEGIN)"
MARKER_END="# dominikwozniak-skills bootstrap (END)"
touch .gitignore

if grep -qF "$MARKER_BEGIN" .gitignore; then
  yellow "↷ .gitignore already has bootstrap block — skipping"
else
  echo "" >> .gitignore
  cat "$TEMPLATES/gitignore-additions" >> .gitignore
  green "✓ appended to .gitignore"
fi

# --- 5. Final reminder ----------------------------------------------------

echo
green "Done."
echo
echo "Next steps:"
echo "  1. In Claude Code, add this marketplace once:"
echo "       /plugin marketplace add file://$REPO_ROOT"
echo "  2. Install plugins inside this project:"
echo "       /plugin install workflow-bootstrap"
echo "       /plugin install git-flow"
echo "       /plugin install handoff"
echo "  3. Make sure these are enabled globally (~/.claude/settings.json):"
echo "       agent-skills (addyosmani), caveman, claude-mem"
echo "  4. Specs/plans land in .agent/. Handoff docs in .agent/handoffs/."
