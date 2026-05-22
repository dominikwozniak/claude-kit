#!/usr/bin/env bash
# Verify the tools claude-kit expects are installed.
# Exit 0 on clean run, 1 if any required tool is missing.

set -uo pipefail

green() { printf "\033[32m%s\033[0m\n" "$1"; }
yellow() { printf "\033[33m%s\033[0m\n" "$1"; }
red() { printf "\033[31m%s\033[0m\n" "$1"; }

missing_required=0

check_required() {
  local name="$1" cmd="$2"
  if command -v "$cmd" >/dev/null 2>&1; then
    green "✓ $name ($cmd)"
  else
    red "✗ $name ($cmd) — REQUIRED, not found"
    missing_required=1
  fi
}

check_optional() {
  local name="$1" cmd="$2" install_hint="$3"
  if command -v "$cmd" >/dev/null 2>&1; then
    green "✓ $name ($cmd)"
  else
    yellow "~ $name ($cmd) — optional, install: $install_hint"
  fi
}

check_claude_plugin() {
  local plugin="$1"
  if grep -q "\"$plugin@" "$HOME/.claude/settings.json" 2>/dev/null; then
    green "✓ claude plugin: $plugin"
  else
    yellow "~ claude plugin: $plugin — not in enabledPlugins"
  fi
}

check_marketplace() {
  local found
  found=$(jq -r '.extraKnownMarketplaces | keys[]?' "$HOME/.claude/settings.json" 2>/dev/null \
    | grep -E '^(claude-kit|dominikwozniak-skills)$' || true)
  if [[ -n "$found" ]]; then
    green "✓ marketplace registered: $found"
  else
    yellow "~ claude-kit marketplace not registered — run /plugin marketplace add github:dominikwozniak/claude-kit"
  fi
}

echo "claude-kit — doctor"
echo "──────────────────────────────"

echo
echo "Required CLI tools:"
check_required "git" "git"
check_required "jq" "jq"
check_required "gh" "gh"
check_required "pnpm" "pnpm"
check_required "node" "node"

echo
echo "Optional CLI tools:"
check_optional "rtk" "rtk" "brew install rtk-ai/rtk/rtk"

echo
echo "Git commit signing:"
check_git_signing() {
  local sk gpgsign
  sk=$(git config --global --get user.signingkey 2>/dev/null || true)
  gpgsign=$(git config --global --get commit.gpgsign 2>/dev/null || true)
  if [[ -n "$sk" && "$gpgsign" == "true" ]]; then
    green "✓ commit signing configured (key + commit.gpgsign=true)"
  else
    yellow "~ commit signing not fully configured"
    [[ -z "$sk" ]] && yellow "  - user.signingkey not set"
    [[ "$gpgsign" != "true" ]] && yellow "  - commit.gpgsign not true"
    yellow "  - see: https://docs.github.com/en/authentication/managing-commit-signature-verification"
  fi
}
check_git_signing

echo
echo "Claude Code plugins (checks ~/.claude/settings.json enabledPlugins):"
check_claude_plugin "caveman"
check_claude_plugin "claude-mem"
check_claude_plugin "agent-skills"

echo
echo "claude-kit marketplace + plugins:"
check_marketplace
check_claude_plugin "bootstrap-workflow"
check_claude_plugin "git-workflow"
check_claude_plugin "session-handoff"
check_claude_plugin "setup-pre-commit"

echo
if [[ $missing_required -ne 0 ]]; then
  red "Required tools missing. Install them before running bootstrap.sh."
  exit 1
fi

green "All required tools present."
