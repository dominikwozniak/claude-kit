#!/usr/bin/env bash
# Verify the tools claude-kit expects are installed.
# Exit 0 on clean run, 1 if any required tool is missing.
#
# Usage:
#   doctor.sh           # human-readable output
#   doctor.sh --json    # machine-readable: {missing, optional_missing, plugin_missing, marketplace_missing}

set -uo pipefail

MODE="human"
[[ "${1:-}" == "--json" ]] && MODE="json"

green() { printf "\033[32m%s\033[0m\n" "$1"; }
yellow() { printf "\033[33m%s\033[0m\n" "$1"; }
red() { printf "\033[31m%s\033[0m\n" "$1"; }
log() { [[ "$MODE" == "human" ]] && "$@"; }
say() { [[ "$MODE" == "human" ]] && echo "$@"; }

MISSING=()
OPT_MISSING=()
PLUGIN_MISSING=()
MARKETPLACE_MISSING=0

check_required() {
  local name="$1" cmd="$2"
  if command -v "$cmd" >/dev/null 2>&1; then
    log green "✓ $name ($cmd)"
  else
    log red "✗ $name ($cmd) — REQUIRED, not found"
    MISSING+=("$cmd")
  fi
}

check_optional() {
  local name="$1" cmd="$2" install_hint="$3"
  if command -v "$cmd" >/dev/null 2>&1; then
    log green "✓ $name ($cmd)"
  else
    log yellow "~ $name ($cmd) — optional, install: $install_hint"
    OPT_MISSING+=("$cmd")
  fi
}

check_claude_plugin() {
  local plugin="$1"
  if grep -q "\"$plugin@" "$HOME/.claude/settings.json" 2>/dev/null; then
    log green "✓ claude plugin: $plugin"
  else
    log yellow "~ claude plugin: $plugin — not in enabledPlugins"
    PLUGIN_MISSING+=("$plugin")
  fi
}

check_marketplace() {
  local found
  found=$(jq -r '.extraKnownMarketplaces | keys[]?' "$HOME/.claude/settings.json" 2>/dev/null \
    | grep -E '^(claude-kit|dominikwozniak-skills)$' || true)
  if [[ -n "$found" ]]; then
    log green "✓ marketplace registered: $found"
  else
    log yellow "~ claude-kit marketplace not registered — run /plugin marketplace add github:dominikwozniak/claude-kit"
    MARKETPLACE_MISSING=1
  fi
}

check_git_signing() {
  local sk gpgsign
  sk=$(git config --global --get user.signingkey 2>/dev/null || true)
  gpgsign=$(git config --global --get commit.gpgsign 2>/dev/null || true)
  if [[ -n "$sk" && "$gpgsign" == "true" ]]; then
    log green "✓ commit signing configured (key + commit.gpgsign=true)"
  else
    log yellow "~ commit signing not fully configured"
    [[ -z "$sk" ]] && log yellow "  - user.signingkey not set"
    [[ "$gpgsign" != "true" ]] && log yellow "  - commit.gpgsign not true"
    log yellow "  - see: https://docs.github.com/en/authentication/managing-commit-signature-verification"
  fi
}

say "claude-kit — doctor"
say "──────────────────────────────"

# Stack detection — required tools depend on which manifests are present.
# When neither manifest is present, fall back to Node (claude-kit's own toolchain).
HAS_RUBY=0
HAS_NODE=0
[[ -f "Gemfile" ]] && HAS_RUBY=1
[[ -f "package.json" ]] && HAS_NODE=1
if [[ $HAS_RUBY -eq 0 && $HAS_NODE -eq 0 ]]; then
  HAS_NODE=1
fi

say
say "Required CLI tools:"
check_required "git" "git"
check_required "jq" "jq"
check_required "gh" "gh"
if [[ $HAS_NODE -eq 1 ]]; then
  check_required "pnpm" "pnpm"
  check_required "node" "node"
fi
if [[ $HAS_RUBY -eq 1 ]]; then
  check_required "ruby" "ruby"
  check_required "bundle" "bundle"
fi

say
say "Optional CLI tools:"
check_optional "rtk" "rtk" "brew install rtk-ai/rtk/rtk"

say
say "Git commit signing:"
check_git_signing

say
say "Claude Code plugins (checks ~/.claude/settings.json enabledPlugins):"
check_claude_plugin "caveman"
check_claude_plugin "claude-mem"
check_claude_plugin "agent-skills"

say
say "claude-kit marketplace + plugins:"
check_marketplace
check_claude_plugin "bootstrap-workflow"
check_claude_plugin "git-workflow"
check_claude_plugin "session-handoff"
check_claude_plugin "setup-pre-commit"

# --- JSON mode output ------------------------------------------------------

if [[ "$MODE" == "json" ]]; then
  to_json_array() {
    if [[ $# -eq 0 ]]; then
      printf '[]'
    else
      printf '%s\n' "$@" | jq -R . | jq -s -c .
    fi
  }
  jq -n -c \
    --argjson missing "$(to_json_array ${MISSING[@]+"${MISSING[@]}"})" \
    --argjson optional_missing "$(to_json_array ${OPT_MISSING[@]+"${OPT_MISSING[@]}"})" \
    --argjson plugin_missing "$(to_json_array ${PLUGIN_MISSING[@]+"${PLUGIN_MISSING[@]}"})" \
    --argjson marketplace_missing "$MARKETPLACE_MISSING" \
    '{missing:$missing, optional_missing:$optional_missing, plugin_missing:$plugin_missing, marketplace_missing:($marketplace_missing==1)}'
  [[ ${#MISSING[@]} -gt 0 ]] && exit 1 || exit 0
fi

say
if [[ ${#MISSING[@]} -gt 0 ]]; then
  red "Required tools missing. Install them before running bootstrap.sh."
  exit 1
fi

green "All required tools present."
