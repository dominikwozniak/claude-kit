#!/usr/bin/env bash
# Verify the tools dominikwozniak-skills expects are installed.
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

echo "dominikwozniak-skills — doctor"
echo "──────────────────────────────"

echo
echo "Required CLI tools:"
check_required "git" "git"
check_required "jq" "jq"
check_required "gh" "gh"

echo
echo "Optional CLI tools:"
check_optional "rtk" "rtk" "brew install rtk-ai/rtk/rtk"
check_optional "Deno" "deno" "brew install deno"
check_optional "pnpm" "pnpm" "brew install pnpm"

echo
echo "Claude Code plugins (checks ~/.claude/settings.json enabledPlugins):"
check_claude_plugin "caveman"
check_claude_plugin "claude-mem"
check_claude_plugin "agent-skills"

echo
if [[ $missing_required -ne 0 ]]; then
  red "Required tools missing. Install them before running bootstrap.sh."
  exit 1
fi

green "All required tools present."
