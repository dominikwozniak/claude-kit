#!/usr/bin/env bash
# Drop claude-kit templates into a target project.
# Everything written is local/gitignored — safe to overwrite.
#
# Usage:
#   bootstrap.sh <target-dir> [flags]
#
# Flags (all optional, defaults install everything):
#   --features=claude-md,settings,gitignore
#       Top-level artifacts to install. Default: all.
#   --hooks=block-dangerous-git,block-non-pnpm,lint-on-edit,lint-on-edit-rb,typecheck-on-stop
#       Hook scripts to drop in .claude/hooks/. Default: all. Empty (--hooks=) installs none.
#   --brew-install=rtk,gh,jq
#       Comma-separated tools to `brew install` if missing. Gated on `command -v brew`. Default: none.
#   --project-name=… --default-branch=… --stack=… --test-cmd=… --lint-cmd=…
#   --typecheck-cmd=… --domain=… --key-dirs=… --deploy=… --gotchas=…
#       CLAUDE.local.md placeholder values. Fall back to auto-detect when absent.
#   --no-prompt
#       Skip every interactive read. Combine with explicit flags for unattended runs.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATES="$REPO_ROOT/templates"

green() { printf "\033[32m%s\033[0m\n" "$1"; }
yellow() { printf "\033[33m%s\033[0m\n" "$1"; }
red() { printf "\033[31m%s\033[0m\n" "$1"; }

# --- Argument parsing -----------------------------------------------------

TARGET=""
FEATURES=""
HOOKS=""
BREW=""
NO_PROMPT=0
FEATURES_SET=0
HOOKS_SET=0

# Placeholder vars (set by --foo=bar flags below)
ARG_project_name=""
ARG_default_branch=""
ARG_stack=""
ARG_test_cmd=""
ARG_lint_cmd=""
ARG_typecheck_cmd=""
ARG_domain=""
ARG_key_dirs=""
ARG_deploy=""
ARG_gotchas=""

for arg in "$@"; do
  case "$arg" in
    --features=*)        FEATURES="${arg#*=}"; FEATURES_SET=1 ;;
    --hooks=*)           HOOKS="${arg#*=}"; HOOKS_SET=1 ;;
    --brew-install=*)    BREW="${arg#*=}" ;;
    --no-prompt)         NO_PROMPT=1 ;;
    --project-name=*)    ARG_project_name="${arg#*=}" ;;
    --default-branch=*)  ARG_default_branch="${arg#*=}" ;;
    --stack=*)           ARG_stack="${arg#*=}" ;;
    --test-cmd=*)        ARG_test_cmd="${arg#*=}" ;;
    --lint-cmd=*)        ARG_lint_cmd="${arg#*=}" ;;
    --typecheck-cmd=*)   ARG_typecheck_cmd="${arg#*=}" ;;
    --domain=*)          ARG_domain="${arg#*=}" ;;
    --key-dirs=*)        ARG_key_dirs="${arg#*=}" ;;
    --deploy=*)          ARG_deploy="${arg#*=}" ;;
    --gotchas=*)         ARG_gotchas="${arg#*=}" ;;
    --*)
      red "Unknown flag: $arg"
      exit 1
      ;;
    *)
      if [[ -z "$TARGET" ]]; then TARGET="$arg"; else
        red "Unexpected positional argument: $arg"
        exit 1
      fi
      ;;
  esac
done

if [[ -z "$TARGET" ]]; then
  red "Usage: $0 <target-dir> [flags]  (run with --help-like inspection of the file header)"
  exit 1
fi

TARGET="$(cd "$TARGET" 2>/dev/null && pwd)" || {
  red "Target directory not found: $1"
  exit 1
}

if [[ ! -d "$TARGET/.git" ]]; then
  red "$TARGET is not a git repository. Run 'git init' first."
  exit 1
fi

# Defaults when unset
[[ $FEATURES_SET -eq 0 ]] && FEATURES="claude-md,settings,gitignore"
[[ $HOOKS_SET -eq 0 ]] && HOOKS="block-dangerous-git,block-non-pnpm,lint-on-edit,lint-on-edit-rb,typecheck-on-stop"

has_feature() { [[ ",$FEATURES," == *",$1,"* ]]; }
has_hook()    { [[ ",$HOOKS," == *",$1,"* ]]; }

echo "Bootstrapping claude-kit into: $TARGET"
echo "  features: ${FEATURES:-(none)}"
echo "  hooks:    ${HOOKS:-(none)}"
[[ -n "$BREW" ]] && echo "  brew:     $BREW"
echo

# --- Doctor (warn-only) ---------------------------------------------------

if [[ -x "$SCRIPT_DIR/doctor.sh" ]]; then
  yellow "Running doctor.sh (warn-only)…"
  "$SCRIPT_DIR/doctor.sh" || yellow "doctor.sh reported missing tools — continuing anyway."
  echo
fi

# --- Optional brew install of missing deps --------------------------------

if [[ -n "$BREW" ]]; then
  if command -v brew >/dev/null 2>&1; then
    IFS=',' read -ra BREW_TOOLS <<< "$BREW"
    for tool in "${BREW_TOOLS[@]}"; do
      [[ -z "$tool" ]] && continue
      if command -v "$tool" >/dev/null 2>&1; then
        green "✓ $tool already installed"
      else
        yellow "→ brew install $tool"
        brew install "$tool" || red "  brew install $tool failed — continuing"
      fi
    done
    echo
  else
    yellow "↷ --brew-install requested but brew not on PATH — skipping"
    echo
  fi
fi

cd "$TARGET" || exit 1
mkdir -p .claude/hooks .agent/handoffs

# --- Helpers ---------------------------------------------------------------

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

# Build the .hooks JSON block from selected hooks. Parallel to HOOKS_BLOCK
# below — same has_hook guards, so what's wired in settings.local.json always
# matches what's copied to .claude/hooks/ and what's documented in CLAUDE.local.md.
build_hooks_json() {
  local pre=() post=() stop=()
  has_hook block-dangerous-git && pre+=('{"type":"command","command":"bash \"${CLAUDE_PROJECT_DIR}/.claude/hooks/block-dangerous-git.sh\""}')
  has_hook block-non-pnpm     && pre+=('{"type":"command","command":"bash \"${CLAUDE_PROJECT_DIR}/.claude/hooks/block-non-pnpm.sh\""}')
  has_hook lint-on-edit       && post+=('{"type":"command","command":"bash \"${CLAUDE_PROJECT_DIR}/.claude/hooks/lint-on-edit.sh\"","timeout":30,"statusMessage":"Linting changed file..."}')
  has_hook lint-on-edit-rb    && post+=('{"type":"command","command":"bash \"${CLAUDE_PROJECT_DIR}/.claude/hooks/lint-on-edit-rb.sh\"","timeout":30,"statusMessage":"Linting changed Ruby file..."}')
  has_hook typecheck-on-stop  && stop+=('{"type":"command","command":"bash \"${CLAUDE_PROJECT_DIR}/.claude/hooks/typecheck-on-stop.sh\"","timeout":60,"statusMessage":"Running typecheck (if TS files changed)..."}')

  local parts=() joined
  if (( ${#pre[@]} > 0 )); then
    joined=$(IFS=,; echo "${pre[*]}")
    parts+=("\"PreToolUse\":[{\"matcher\":\"Bash\",\"hooks\":[${joined}]}]")
  fi
  if (( ${#post[@]} > 0 )); then
    joined=$(IFS=,; echo "${post[*]}")
    parts+=("\"PostToolUse\":[{\"matcher\":\"Write|Edit|MultiEdit\",\"hooks\":[${joined}]}]")
  fi
  if (( ${#stop[@]} > 0 )); then
    joined=$(IFS=,; echo "${stop[*]}")
    parts+=("\"Stop\":[{\"hooks\":[${joined}]}]")
  fi

  if (( ${#parts[@]} == 0 )); then
    echo "{}"
  else
    joined=$(IFS=,; echo "${parts[*]}")
    echo "{${joined}}"
  fi
}

# Resolve placeholder value: flag wins; else prompt (unless --no-prompt); else suggestion.
resolve() {
  local flag_val="$1" label="$2" suggestion="$3" reply
  if [[ -n "$flag_val" ]]; then
    echo "$flag_val"
    return
  fi
  if [[ $NO_PROMPT -eq 1 ]]; then
    echo "$suggestion"
    return
  fi
  read -r -p "  $label [$suggestion]: " reply </dev/tty
  echo "${reply:-$suggestion}"
}

# --- 1. CLAUDE.local.md (root) --------------------------------------------

if has_feature claude-md; then
  PROJECT_NAME_DEFAULT="$(basename "$TARGET")"
  DEFAULT_BRANCH_DEFAULT="$(detect_default_branch)"
  STACK_DEFAULT="$(detect_stack)"

  # Stack-aware test/lint/typecheck defaults
  TEST_DEFAULT=""; LINT_DEFAULT=""; TYPECHECK_DEFAULT=""
  case "$STACK_DEFAULT" in
    Ruby)
      if grep -qE '^[[:space:]]*gem[[:space:]]+["'"'"']standard["'"'"']' Gemfile 2>/dev/null; then
        LINT_DEFAULT="bundle exec standardrb --fix"
      elif grep -qE '^[[:space:]]*gem[[:space:]]+["'"'"']rubocop' Gemfile 2>/dev/null; then
        LINT_DEFAULT="bundle exec rubocop -A"
      fi
      if grep -qE '^[[:space:]]*gem[[:space:]]+["'"'"']rspec' Gemfile 2>/dev/null; then
        TEST_DEFAULT="bundle exec rspec"
      elif [[ -x bin/rails ]]; then
        TEST_DEFAULT="bin/rails test"
      fi
      ;;
    "TypeScript / Node"|"JavaScript / Node"|"Deno / TypeScript")
      TEST_DEFAULT="$(read_pkg_script test)";       [[ -z "$TEST_DEFAULT"      ]] && TEST_DEFAULT="pnpm test"
      LINT_DEFAULT="$(read_pkg_script lint)";       [[ -z "$LINT_DEFAULT"      ]] && LINT_DEFAULT="pnpm lint"
      TYPECHECK_DEFAULT="$(read_pkg_script typecheck)"; [[ -z "$TYPECHECK_DEFAULT" ]] && TYPECHECK_DEFAULT="pnpm typecheck"
      ;;
  esac

  if [[ $NO_PROMPT -eq 0 ]]; then
    echo
    echo "Confirm project specifics (press Enter to accept suggestion):"
  fi

  PROJECT_NAME=$(resolve "$ARG_project_name"   "Project name"        "$PROJECT_NAME_DEFAULT")
  DEFAULT_BRANCH=$(resolve "$ARG_default_branch" "Default branch"    "$DEFAULT_BRANCH_DEFAULT")
  STACK=$(resolve "$ARG_stack"                  "Stack"              "$STACK_DEFAULT")
  TEST_CMD=$(resolve "$ARG_test_cmd"            "Test command"       "$TEST_DEFAULT")
  LINT_CMD=$(resolve "$ARG_lint_cmd"            "Lint command"       "$LINT_DEFAULT")
  TYPECHECK_CMD=$(resolve "$ARG_typecheck_cmd"  "Typecheck command"  "$TYPECHECK_DEFAULT")

  if [[ $NO_PROMPT -eq 0 ]]; then
    echo
    echo "Project context (1 line each — Enter to skip, fill later):"
  fi
  DOMAIN_BLURB=$(resolve "$ARG_domain"     "Domain blurb (what this project does)"     "_(fill in later)_")
  KEY_DIRS=$(resolve "$ARG_key_dirs"       "Key directories (e.g. src/, packages/api/)" "_(fill in later)_")
  DEPLOY_TARGET=$(resolve "$ARG_deploy"    "Deployment target (e.g. Vercel, AWS Lambda, n/a)" "_(fill in later)_")
  GOTCHAS=$(resolve "$ARG_gotchas"         "Known gotchas (optional)"                  "_(fill in later)_")

  # Render commands: backtick-quoted when set, italic n/a when empty
  render_cmd() {
    if [[ -z "$1" ]]; then printf '%s' '_(n/a)_'
    else printf '`%s`' "$1"
    fi
  }
  TEST_RENDER="$(render_cmd "$TEST_CMD")"
  LINT_RENDER="$(render_cmd "$LINT_CMD")"
  TYPECHECK_RENDER="$(render_cmd "$TYPECHECK_CMD")"

  # Build the Hooks-installed block from selected hooks (raw commands so the
  # rendered line stays faithful to what each hook actually runs).
  HOOKS_BLOCK=""
  if has_hook block-dangerous-git; then
    HOOKS_BLOCK+='PreToolUse `Bash` → `block-dangerous-git.sh` (blocks force-push, hard-reset, clean -f, etc.)'$'\n'
  fi
  if has_hook block-non-pnpm; then
    HOOKS_BLOCK+='PreToolUse `Bash` → `block-non-pnpm.sh` (enforces pnpm — blocks `npm install`/`yarn`/`bun add`; `npx` and `pnpm dlx` are allowed)'$'\n'
  fi
  if has_hook lint-on-edit; then
    HOOKS_BLOCK+="PostToolUse \`Write|Edit|MultiEdit\` → \`lint-on-edit.sh\` (runs ${LINT_RENDER} on the edited file)"$'\n'
  fi
  if has_hook lint-on-edit-rb; then
    HOOKS_BLOCK+="PostToolUse \`Write|Edit|MultiEdit\` → \`lint-on-edit-rb.sh\` (runs ${LINT_RENDER} on edited \`.rb\` files via bundle exec)"$'\n'
  fi
  if has_hook typecheck-on-stop; then
    HOOKS_BLOCK+="Stop → \`typecheck-on-stop.sh\` (runs ${TYPECHECK_RENDER} when TS files changed)"$'\n'
  fi
  [[ -z "$HOOKS_BLOCK" ]] && HOOKS_BLOCK='_(none)_'$'\n'

  HOOKS_TMP="$(mktemp)"
  printf '%s' "$HOOKS_BLOCK" > "$HOOKS_TMP"

  sed \
    -e "s|{{PROJECT_NAME}}|$PROJECT_NAME|g" \
    -e "s|{{DEFAULT_BRANCH}}|$DEFAULT_BRANCH|g" \
    -e "s|{{STACK}}|$STACK|g" \
    -e "s|{{TEST_COMMAND}}|$TEST_RENDER|g" \
    -e "s|{{LINT_COMMAND}}|$LINT_RENDER|g" \
    -e "s|{{TYPECHECK_COMMAND}}|$TYPECHECK_RENDER|g" \
    -e "s|{{DOMAIN_BLURB}}|$DOMAIN_BLURB|g" \
    -e "s|{{KEY_DIRS}}|$KEY_DIRS|g" \
    -e "s|{{DEPLOY_TARGET}}|$DEPLOY_TARGET|g" \
    -e "s|{{GOTCHAS}}|$GOTCHAS|g" \
    "$TEMPLATES/CLAUDE.local.md" \
  | awk -v hooks_file="$HOOKS_TMP" '
      /\{\{HOOKS_INSTALLED\}\}/ {
        while ((getline line < hooks_file) > 0) print line
        close(hooks_file)
        next
      }
      { print }
    ' > CLAUDE.local.md
  rm -f "$HOOKS_TMP"
  green "✓ CLAUDE.local.md (root, gitignored)"
else
  yellow "↷ skipped CLAUDE.local.md (not in --features)"
fi

# --- 2. .claude/settings.local.json ---------------------------------------

if has_feature settings; then
  HOOKS_JSON="$(build_hooks_json)"
  # Bash parameter expansion — no escape interpretation (JSON has \" and {…}).
  while IFS= read -r line || [[ -n "$line" ]]; do
    printf '%s\n' "${line//\{\{HOOKS_JSON\}\}/$HOOKS_JSON}"
  done < "$TEMPLATES/settings.local.json.tmpl" > .claude/settings.local.json

  # Best-effort pretty-print when jq is available; minified output is also valid.
  if command -v jq >/dev/null 2>&1; then
    tmp="$(mktemp)" && jq . .claude/settings.local.json > "$tmp" && mv "$tmp" .claude/settings.local.json
  fi
  green "✓ .claude/settings.local.json"
else
  yellow "↷ skipped .claude/settings.local.json (not in --features)"
fi

# --- 3. Hook scripts ------------------------------------------------------

for hook in block-dangerous-git.sh block-non-pnpm.sh lint-on-edit.sh lint-on-edit-rb.sh typecheck-on-stop.sh; do
  hook_key="${hook%.sh}"
  if has_hook "$hook_key"; then
    cp "$TEMPLATES/hooks/$hook" ".claude/hooks/$hook"
    chmod +x ".claude/hooks/$hook"
    green "✓ .claude/hooks/$hook"
  else
    yellow "↷ skipped .claude/hooks/$hook (not in --hooks)"
  fi
done

# --- 4. .gitignore additions (idempotent via marker) ----------------------

if has_feature gitignore; then
  MARKER_BEGIN="# claude-kit bootstrap (BEGIN)"
  touch .gitignore

  if grep -qF "$MARKER_BEGIN" .gitignore; then
    yellow "↷ .gitignore already has bootstrap block — skipping"
  else
    echo "" >> .gitignore
    cat "$TEMPLATES/gitignore-additions" >> .gitignore
    green "✓ appended to .gitignore"
  fi
else
  yellow "↷ skipped .gitignore additions (not in --features)"
fi

# --- 5. Final reminder ----------------------------------------------------

echo
green "Done."
echo
echo "Next steps:"
echo "  1. If not already added, register the marketplace in Claude Code:"
echo "       /plugin marketplace add github:dominikwozniak/claude-kit"
echo "  2. Install companion plugins inside this project:"
echo "       /plugin install git-workflow"
echo "       /plugin install session-handoff"
echo "  3. Make sure these are enabled globally (~/.claude/settings.json):"
echo "       agent-skills (addyosmani), caveman, claude-mem"
echo "  4. Specs/plans land in .agent/. Handoff docs in .agent/handoffs/."
