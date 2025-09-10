#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${SCRIPT_DIR}"

# Allow testing in a sandbox by overriding destination home (link targets, config writes)
TARGET_HOME="${DOTFILES_TARGET_HOME:-$HOME}"

usage() {
    cat <<EOF
Opinionated macOS bootstrap (Apple Silicon focused)

Usage: $(basename "$0") [options]
    --no-brew            Skip Homebrew install & bundle
    --no-dotfiles        Skip linking dotfiles
    --no-omz             Skip Oh My Zsh install
    --no-vscode          Skip VS Code settings/extension handling
    --no-defaults        Skip macOS defaults script (new_mac_defaults.sh apply)
    --dry-run            Show actions without executing
    --force              Overwrite existing backups/symlinks without prompt
    -h, --help           Show this help

Re-run safe: idempotent linking + guarded installs.
EOF
}

DRY_RUN=false
DO_BREW=true
DO_DOTFILES=true
DO_OMZ=true
DO_VSCODE=true
DO_DEFAULTS=true
FORCE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --no-brew) DO_BREW=false ; shift ;;
        --no-dotfiles) DO_DOTFILES=false ; shift ;;
        --no-omz) DO_OMZ=false ; shift ;;
        --no-vscode) DO_VSCODE=false ; shift ;;
        --no-defaults) DO_DEFAULTS=false ; shift ;;
        --dry-run) DRY_RUN=true ; shift ;;
        --force) FORCE=true ; shift ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: $1"; usage; exit 1 ;;
    esac
done

run() {
    if $DRY_RUN; then
        echo "[dry-run] $*"
    else
        echo "+ $*"
        eval "$@"
    fi
}

ensure_xcode() {
    if ! xcode-select -p &>/dev/null; then
        echo "Installing Xcode command line tools..."
        run "xcode-select --install || true" # GUI interaction required
    else
        echo "Xcode command line tools already installed"
    fi
}

install_homebrew() {
    if command -v brew >/dev/null 2>&1; then
        echo "Homebrew already installed"
    else
        echo "Installing Homebrew..."
        run "/bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    fi
    # Apple Silicon specific path
    if ! grep -q 'brew shellenv' "$TARGET_HOME/.zprofile" 2>/dev/null; then
    run "(echo; echo 'eval \"$(/opt/homebrew/bin/brew shellenv)\"') >> $TARGET_HOME/.zprofile"
    fi
    # shellcheck disable=SC2046
    eval "$($(command -v brew) shellenv)"
}

brew_bundle() {
    echo "Running brew bundle (Brewfile)..."
    run "brew bundle --file=$REPO_ROOT/Brewfile"
}

install_oh_my_zsh() {
    if [ -d "$HOME/.oh-my-zsh" ]; then
        echo "Oh My Zsh already installed"
    else
        echo "Installing Oh My Zsh (non-interactive)..."
        run "RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \"$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\""
    fi
}

backup_then_link() {
    local src="$1"; shift
    local dest="$1"; shift
    if [ -e "$dest" ] && [ ! -L "$dest" ]; then
        local backup="${dest}.backup.$(date +%Y%m%d%H%M%S)"
        if $FORCE; then
            run "mv '$dest' '$backup'"
        else
            echo "Backing up existing $dest -> $backup"
            run "mv '$dest' '$backup'"
        fi
    fi
    # Always link (force to update if changed)
    run "ln -snf '$src' '$dest'"
}

link_dotfiles() {
    echo "Linking dotfiles..."
    local FILES=(.zshrc .gitignore .aliases vs_code.user.settings.json)
    # Template-able gitconfig: only link if not existing
    if [ ! -f "$TARGET_HOME/.gitconfig" ]; then
        FILES+=(.gitconfig)
    else
        echo "Skipping .gitconfig (already exists)"
    fi
    for f in "${FILES[@]}"; do
        backup_then_link "$REPO_ROOT/$f" "$TARGET_HOME/$f"
    done
    # VS Code settings target
    if $DO_VSCODE; then
    local VSC_TARGET="$TARGET_HOME/Library/Application Support/Code/User/settings.json"
        mkdir -p "$(dirname "$VSC_TARGET")"
        backup_then_link "$REPO_ROOT/vs_code.user.settings.json" "$VSC_TARGET"
    fi
}

apply_defaults() {
    if $DO_DEFAULTS; then
        if [ -x "$REPO_ROOT/new_mac_defaults.sh" ]; then
            echo "Applying macOS defaults (apply)..."
            run "$REPO_ROOT/new_mac_defaults.sh" apply || echo "Defaults script returned non-zero (review logs)"
        else
            echo "Defaults script not executable or missing"
        fi
    fi
}

post_install_notes() {
    cat <<EOF
\nBootstrap complete.
Next steps (manual suggestions):
    - Launch VS Code once to finalize extension installs.
    - Review backed up originals (*.backup.YYYYMMDDHHMMSS) if any.
    - Run 'brewup' periodically to update packages.
EOF
}

main() {
    ensure_xcode
    $DO_BREW && install_homebrew
    $DO_BREW && brew_bundle
    $DO_OMZ && install_oh_my_zsh
    $DO_DOTFILES && link_dotfiles
    apply_defaults
    post_install_notes
}

main "$@"
