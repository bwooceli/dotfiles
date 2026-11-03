#!/usr/bin/env bash
set -euo pipefail

echo "[bootstrap] Starting minimal bootstrap for dotfiles (Apple Silicon assumed)."

# Repository metadata (override via env if you fork)
REPO_OWNER_DEFAULT="bwooceli"
REPO_OWNER="${REPO_OWNER:-$REPO_OWNER_DEFAULT}"
REPO_NAME="dotfiles"
BRANCH="main"
TARGET_DIR="${TARGET_DIR:-$HOME/dotfiles}"

PERSONALIZE_PLACEHOLDERS=("YOUR_GITHUB_USERNAME" "YOUR_NAME" "YOUR_EMAIL@example.com")

has_placeholder_tokens() {
  (grep -RIl --exclude-dir .git -e "${PERSONALIZE_PLACEHOLDERS[0]}" -e "${PERSONALIZE_PLACEHOLDERS[1]}" -e "${PERSONALIZE_PLACEHOLDERS[2]}" "$TARGET_DIR" >/dev/null 2>&1) || return 1
}

prompt_personalize() {
  # Only run if placeholders exist and personalize.sh is present
  if ! has_placeholder_tokens; then
    return 0
  fi
  if [ ! -x "$TARGET_DIR/personalize.sh" ]; then
    echo "[bootstrap] personalize.sh missing or not executable; skipping identity prompts."; return 0
  fi
  echo "[bootstrap] Detected placeholder identity tokens in repository."
  # Ask user
  read -r -p "Would you like to personalize now? [Y/n] " ans
  case "${ans:-Y}" in
    n|N) echo "[bootstrap] Skipping personalization (you can run ./personalize.sh later)."; return 0 ;;
  esac

  # Derive sensible defaults from existing global git config if available
  DEFAULT_GH="${GITHUB_USERNAME:-$(git config --global github.user 2>/dev/null || true)}"
  DEFAULT_NAME="${REAL_NAME:-$(git config --global user.name 2>/dev/null || true)}"
  DEFAULT_EMAIL="${REAL_EMAIL:-$(git config --global user.email 2>/dev/null || true)}"

  read -r -p "GitHub username [${DEFAULT_GH:-none}]: " GITHUB_USERNAME_INPUT
  read -r -p "Full name        [${DEFAULT_NAME:-none}]: " REAL_NAME_INPUT
  read -r -p "Email            [${DEFAULT_EMAIL:-none}]: " REAL_EMAIL_INPUT

  GITHUB_USERNAME="${GITHUB_USERNAME_INPUT:-$DEFAULT_GH}"
  REAL_NAME="${REAL_NAME_INPUT:-$DEFAULT_NAME}"
  REAL_EMAIL="${REAL_EMAIL_INPUT:-$DEFAULT_EMAIL}"

  if [ -z "$GITHUB_USERNAME" ] || [ -z "$REAL_NAME" ] || [ -z "$REAL_EMAIL" ]; then
    echo "[bootstrap] One or more values empty; skipping personalization (run ./personalize.sh later)."
    return 0
  fi

  echo "[bootstrap] Applying personalization..."
  (
    cd "$TARGET_DIR" || exit 1
    GITHUB_USERNAME="$GITHUB_USERNAME" REAL_NAME="$REAL_NAME" REAL_EMAIL="$REAL_EMAIL" ./personalize.sh --github "$GITHUB_USERNAME" --name "$REAL_NAME" --email "$REAL_EMAIL" || echo "[bootstrap] Personalization script returned non-zero; continuing."
  )
}

has_cmd() { command -v "$1" >/dev/null 2>&1; }

if ! has_cmd xcode-select || ! xcode-select -p >/dev/null 2>&1; then
  echo "[bootstrap] Triggering Xcode Command Line Tools install (if GUI appears, complete it, then re-run)."
  xcode-select --install || true
  # We cannot proceed reliably until the user finishes installation.
  echo "[bootstrap] Re-run this command after Xcode tools finish installing."
  exit 0
fi

# If git not yet available (sometimes appears only after CLT finish), we can still fetch via curl/tar.
fetch_repo() {
  if [ -d "$TARGET_DIR/.git" ]; then
    echo "[bootstrap] Repo already present; pulling updates."
    (cd "$TARGET_DIR" && git pull --ff-only || true)
    return
  fi
  if has_cmd git; then
    echo "[bootstrap] Cloning with git..."
    git clone --depth 1 "https://github.com/$REPO_OWNER/$REPO_NAME.git" "$TARGET_DIR"
  else
    echo "[bootstrap] git not available yet; falling back to tarball download."
    TMP_DIR=$(mktemp -d)
    TAR_URL="https://codeload.github.com/$REPO_OWNER/$REPO_NAME/tar.gz/refs/heads/$BRANCH"
    echo "[bootstrap] Downloading $TAR_URL"
    curl -fsSL "$TAR_URL" | tar -xz -C "$TMP_DIR"
    mv "$TMP_DIR/$REPO_NAME-$BRANCH" "$TARGET_DIR"
    rm -rf "$TMP_DIR"
  fi
}

fetch_repo

if ! has_cmd brew; then
  echo "[bootstrap] Installing Homebrew (if not present) ..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [ -d /opt/homebrew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
fi

cd "$TARGET_DIR"

# Optionally personalize before running main setup so linked files have real identity
if [ -z "${DOTFILES_NO_PERSONALIZE:-}" ]; then
  prompt_personalize || true
else
  echo "[bootstrap] DOTFILES_NO_PERSONALIZE set; skipping personalization."
fi

echo "[bootstrap] Running primary setup script (my_mac_setup.sh) with passed arguments: $*"
chmod +x ./my_mac_setup.sh || true
./my_mac_setup.sh "$@"

echo "[bootstrap] Complete."