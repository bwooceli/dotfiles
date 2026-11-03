#!/usr/bin/env bash
set -euo pipefail

# Hardened + idempotent GitHub SSH setup helper.
# Features added:
#   * set -euo pipefail
#   * Skips resetting git config if already matches
#   * Reuses existing ssh-agent if possible
#   * Only adds key to agent if not already listed
#   * Safe creation of ~/.ssh and config stanza
#   * Flags for non-interactive usage: --username, --email, --no-remote-update, --quiet

USERNAME=""
EMAIL=""
DO_REMOTE_PROMPT=true
QUIET=false

usage() {
    cat <<EOF
Usage: $(basename "$0") [options]
    --username <github_user>
    --email <email>
    --no-remote-update    Skip prompt about converting an existing repo remote
    --quiet               Minimal output
    -h, --help            Help
If username/email omitted, prompts will appear (interactive mode).
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --username) USERNAME="$2"; shift 2;;
        --email) EMAIL="$2"; shift 2;;
        --no-remote-update) DO_REMOTE_PROMPT=false; shift;;
        --quiet) QUIET=true; shift;;
        -h|--help) usage; exit 0;;
        *) echo "Unknown option: $1" >&2; usage; exit 1;;
    esac
done

log() { $QUIET || echo "$*"; }

log "🔍 Checking if Git is installed..."
if ! command -v git &>/dev/null; then
    log "❌ Git is not installed. Triggering Xcode Command Line Tools..."
    xcode-select --install || true
    log "➡️  Re-run after installation completes."
    exit 1
fi
log "✅ Git is installed."

if [[ -z "$USERNAME" ]]; then
    read -rp "👤 Enter your GitHub username: " USERNAME
fi
if [[ -z "$EMAIL" ]]; then
    read -rp "📧 Enter your GitHub email: " EMAIL
fi

current_name=$(git config --global user.name 2>/dev/null || true)
current_email=$(git config --global user.email 2>/dev/null || true)
if [[ "$current_name" == "$USERNAME" && "$current_email" == "$EMAIL" ]]; then
    log "✅ Global git identity already set (name/email unchanged)."
else
    git config --global user.name "$USERNAME"
    git config --global user.email "$EMAIL"
    log "✅ Git username and email set." 
fi

SSH_DIR="$HOME/.ssh"
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"
SSH_KEY="$SSH_DIR/id_ed25519"
if [[ -f "$SSH_KEY" ]]; then
    log "🔑 SSH key already exists: $SSH_KEY"
else
    log "🔑 Generating a new SSH key..."
    ssh-keygen -t ed25519 -C "$EMAIL" -f "$SSH_KEY" -N ""
    log "✅ SSH key generated."
fi

# Reuse existing agent if possible; launch if not.
if [[ -S ${SSH_AUTH_SOCK:-} ]] && ssh-add -l &>/dev/null; then
    log "🔐 Using existing ssh-agent."
else
    log "🚀 Starting new ssh-agent..."
    # shellcheck disable=SC2046
    eval $(ssh-agent -s)
fi

# Add key only if not already present
if ssh-add -l 2>/dev/null | grep -q "$(ssh-keygen -lf "$SSH_KEY" | awk '{print $2}')"; then
    log "🔗 Key already loaded in agent."
else
    log "🔗 Adding SSH key to agent..."
    ssh-add --apple-use-keychain "$SSH_KEY"
    log "✅ SSH key added."
fi

SSH_CONFIG="$SSH_DIR/config"
if ! grep -q "Host github.com" "$SSH_CONFIG" 2>/dev/null; then
    log "📝 Configuring SSH to use the keychain..."
    {
        echo "Host github.com"
        echo "  AddKeysToAgent yes"
        echo "  IdentityFile $SSH_KEY"
        echo "  UseKeychain yes"
    } >> "$SSH_CONFIG"
    chmod 600 "$SSH_CONFIG"
    log "✅ SSH config updated."
else
    log "✅ SSH config already set up."
fi

if command -v pbcopy >/dev/null 2>&1; then
    log "📋 Copying SSH public key to clipboard..."
    pbcopy < "$SSH_KEY.pub"
    log "✅ Public key copied. Add it at: https://github.com/settings/keys"
else
    log "🔎 pbcopy not available; display key below:\n$(cat "$SSH_KEY.pub")"
fi

if [[ -t 0 ]]; then
    read -rp "🔔 Press Enter after adding the key to GitHub..." _junk || true
fi

log "🔍 Testing SSH connection to GitHub (expect 'success' or first-time warning)..."
set +e
ssh -T git@github.com 2>&1 | sed 's/^/    /'
rc=${PIPESTATUS[0]}
set -e
if [[ $rc -eq 1 || $rc -eq 0 ]]; then
    # GitHub returns 1 on first auth success without shell.
    log "✅ Authentication step complete (exit $rc)."
else
    log "❌ SSH test failed (exit $rc). Review above output."; exit $rc
fi

if $DO_REMOTE_PROMPT && [[ -t 0 ]]; then
    read -rp "📂 Update an existing repo remote from HTTPS to SSH? (y/N): " UPDATE_REPO
    if [[ $UPDATE_REPO == [yY] ]]; then
        read -rp "📂 Path to repo: " REPO_PATH
        if [[ -d "$REPO_PATH/.git" ]]; then
            pushd "$REPO_PATH" >/dev/null || exit 1
            OLD_REMOTE=$(git remote get-url origin 2>/dev/null || true)
            if [[ -n "$OLD_REMOTE" && "$OLD_REMOTE" == https://github.com/* ]]; then
                NEW_REMOTE=${OLD_REMOTE/https:\/\/github.com\//git@github.com:}
                git remote set-url origin "$NEW_REMOTE"
                log "✅ Updated remote: $NEW_REMOTE"
            else
                log "ℹ️  Remote already SSH or missing; skipped."
            fi
            popd >/dev/null || true
        else
            log "⚠️  Not a git repo: $REPO_PATH"
        fi
    fi
fi

log "🎉 GitHub SSH setup complete."