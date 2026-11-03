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

# Pass commands as separate arguments (no eval), so nothing is expanded early.
run() {
    local IFS=' ' # print "$*" space-separated despite the script-wide IFS
    if $DRY_RUN; then
        echo "[dry-run] $*"
    else
        echo "+ $*"
        "$@"
    fi
}

# run_installer <name> <shell> <url> [VAR=value ...]
# Downloads the installer only when actually running (not during --dry-run).
run_installer() {
    local name="$1" shell="$2" url="$3"; shift 3
    if $DRY_RUN; then
        echo "[dry-run] download and run $name installer from $url ${*:-}"
        return 0
    fi
    local script
    script="$(curl -fsSL "$url")"
    echo "+ running $name installer"
    env "$@" "$shell" -c "$script"
}

find_brew() {
    command -v brew 2>/dev/null && return 0
    local p
    for p in /opt/homebrew/bin/brew /usr/local/bin/brew; do
        if [ -x "$p" ]; then echo "$p"; return 0; fi
    done
    return 1
}

ensure_xcode() {
    if ! xcode-select -p &>/dev/null; then
        echo "Installing Xcode command line tools..."
        run xcode-select --install || true # GUI interaction required
        if ! $DRY_RUN; then
            echo "Re-run this script after the Xcode command line tools finish installing."
            exit 0
        fi
    else
        echo "Xcode command line tools already installed"
    fi
}

install_homebrew() {
    local brew_bin
    if brew_bin="$(find_brew)"; then
        echo "Homebrew already installed ($brew_bin)"
    else
        echo "Installing Homebrew..."
        run_installer Homebrew /bin/bash https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh
        if ! brew_bin="$(find_brew)"; then
            if $DRY_RUN; then
                echo "[dry-run] would add brew shellenv to $TARGET_HOME/.zprofile"
                return 0
            fi
            echo "Homebrew install finished but brew was not found" >&2
            exit 1
        fi
    fi
    # Persist brew on PATH for future login shells (literal line, expanded at login)
    if ! grep -q 'brew shellenv' "$TARGET_HOME/.zprofile" 2>/dev/null; then
        if $DRY_RUN; then
            echo "[dry-run] append 'eval \"\$($brew_bin shellenv)\"' to $TARGET_HOME/.zprofile"
        else
            # shellcheck disable=SC2016
            printf '\neval "$(%s shellenv)"\n' "$brew_bin" >> "$TARGET_HOME/.zprofile"
        fi
    fi
    # And for the rest of this script
    eval "$("$brew_bin" shellenv)"
}

brew_bundle() {
    echo "Running brew bundle (Brewfile)..."
    run brew bundle --file="$REPO_ROOT/Brewfile"
}

install_oh_my_zsh() {
    if [ -d "$HOME/.oh-my-zsh" ]; then
        echo "Oh My Zsh already installed"
    else
        echo "Installing Oh My Zsh (non-interactive)..."
        run_installer "Oh My Zsh" /bin/sh https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh \
            RUNZSH=no CHSH=no KEEP_ZSHRC=yes
    fi
}

backup_then_link() {
    local src="$1"; shift
    local dest="$1"; shift
    if [ -e "$dest" ] && [ ! -L "$dest" ]; then
        local backup
        backup="${dest}.backup.$(date +%Y%m%d%H%M%S)"
        echo "Backing up existing $dest -> $backup"
        run mv "$dest" "$backup"
    fi
    # Always link (force to update if changed)
    run ln -snf "$src" "$dest"
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
        run mkdir -p "$(dirname "$VSC_TARGET")"
        backup_then_link "$REPO_ROOT/vs_code.user.settings.json" "$VSC_TARGET"
    fi
}

apply_defaults() {
    if $DO_DEFAULTS; then
        if [ -x "$REPO_ROOT/new_mac_defaults.sh" ]; then
            echo "Applying macOS defaults (apply)..."
            local defaults_args=(apply)
            if $DRY_RUN; then defaults_args+=(--dry-run); fi
            # Run even in dry-run: the defaults script has its own dry-run mode
            "$REPO_ROOT/new_mac_defaults.sh" "${defaults_args[@]}" || echo "Defaults script returned non-zero (review logs)"
        else
            echo "Defaults script not executable or missing"
        fi
    fi
}

post_install_notes() {
    cat <<EOF

Bootstrap complete.
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
