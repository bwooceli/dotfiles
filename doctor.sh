#!/usr/bin/env bash
set -euo pipefail

echo "== Dotfiles Doctor =="

pass=0
fail=0
check() {
  local msg="$1"; shift
  if eval "$@" >/dev/null 2>&1; then
    echo "[OK]  $msg"
    ((pass++))
  else
    echo "[ERR] $msg"
    ((fail++))
  fi
}

# Brew
check "Homebrew installed" "command -v brew"

# Oh My Zsh
check "Oh My Zsh present" "[ -d $HOME/.oh-my-zsh ]"

# Symlinks
for f in .zshrc .aliases .gitignore vs_code.user.settings.json; do
  check "Symlink $f" "[ -L $HOME/$f ]"
done

# VS Code settings location symlinked
VCODE_SETTINGS="$HOME/Library/Application Support/Code/User/settings.json"
check "VS Code settings symlink" "[ -L '$VCODE_SETTINGS' ]"

# Zsh plugins available
check "zsh-autosuggestions plugin" "[ -f $(brew --prefix 2>/dev/null)/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]"
check "zsh-syntax-highlighting plugin" "[ -f $(brew --prefix 2>/dev/null)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]"

echo "\nSummary: $pass passed, $fail failed"
if (( fail > 0 )); then
  exit 1
fi
echo "All good!"