#!/usr/bin/env bash
set -euo pipefail

echo "[bootstrap] Starting minimal bootstrap for dotfiles (Apple Silicon assumed)."

REPO_OWNER="YOUR_GITHUB_USERNAME"
REPO_NAME="dotfiles"
BRANCH="main"
TARGET_DIR="$HOME/dotfiles"

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

echo "[bootstrap] Running primary setup script (my_mac_setup.sh) with passed arguments: $*"
chmod +x ./my_mac_setup.sh || true
./my_mac_setup.sh "$@"

echo "[bootstrap] Complete."