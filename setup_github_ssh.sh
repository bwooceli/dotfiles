#!/bin/bash

# Make the script executable:
# chmod +x setup_github_ssh.sh

echo "🔍 Checking if Git is installed..."
if ! command -v git &>/dev/null; then
    echo "❌ Git is not installed. Installing now..."
    xcode-select --install
    echo "✅ Git installation started. Please complete the installation and re-run this script."
    exit 1
else
    echo "✅ Git is installed."
fi

# Set up Git username and email
echo -n "👤 Enter your GitHub username: "
read GIT_USERNAME
echo -n "📧 Enter your GitHub email: "
read GIT_EMAIL

git config --global user.name "$GIT_USERNAME"
git config --global user.email "$GIT_EMAIL"

echo "✅ Git username and email set."

# Check if an SSH key already exists
SSH_KEY="$HOME/.ssh/id_ed25519"
if [ -f "$SSH_KEY" ]; then
    echo "🔑 SSH key already exists: $SSH_KEY"
else
    echo "🔑 Generating a new SSH key..."
    ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$SSH_KEY" -N ""
    echo "✅ SSH key generated."
fi

# Ensure the SSH agent is running
echo "🚀 Starting SSH agent..."
eval "$(ssh-agent -s)"
echo "✅ SSH agent started."

# Add key to SSH agent
echo "🔗 Adding SSH key to agent..."
ssh-add --apple-use-keychain "$SSH_KEY"
echo "✅ SSH key added."

# Configure SSH to use keychain
SSH_CONFIG="$HOME/.ssh/config"
if ! grep -q "Host github.com" "$SSH_CONFIG" 2>/dev/null; then
    echo "📝 Configuring SSH to use the keychain..."
    cat <<EOF >> "$SSH_CONFIG"

Host github.com
  AddKeysToAgent yes
  IdentityFile $SSH_KEY
  UseKeychain yes
EOF
    echo "✅ SSH config updated."
else
    echo "✅ SSH config already set up."
fi

# Copy SSH key to clipboard and prompt user
echo "📋 Copying SSH key to clipboard..."
pbcopy < "$SSH_KEY.pub"
echo "✅ SSH key copied to clipboard."

echo -e "\n🛠️ Go to GitHub → Settings → SSH and GPG Keys"
echo "🔗 Open this link in your browser: https://github.com/settings/keys"
echo "➕ Click 'New SSH Key' and paste the key."
echo "🔔 Press Enter when you've added the key to GitHub..."
read -r

# Test the SSH connection
echo "🔍 Testing SSH connection to GitHub..."
ssh -T git@github.com
if [ $? -eq 0 ]; then
    echo "✅ Authentication successful!"
else
    echo "❌ Authentication failed. Check your SSH key setup."
    exit 1
fi

# Optionally update an existing repo to use SSH
echo -n "📂 Do you want to update an existing Git repository to use SSH? (y/N): "
read UPDATE_REPO
if [[ "$UPDATE_REPO" == "y" || "$UPDATE_REPO" == "Y" ]]; then
    echo -n "📂 Enter the path to your Git repository: "
    read REPO_PATH
    cd "$REPO_PATH" || { echo "❌ Invalid path."; exit 1; }
    OLD_REMOTE=$(git remote get-url origin)
    NEW_REMOTE=$(echo "$OLD_REMOTE" | sed 's|https://github.com/|git@github.com:|')
    git remote set-url origin "$NEW_REMOTE"
    echo "✅ Updated remote to SSH: $NEW_REMOTE"
fi

echo "🎉 GitHub SSH setup complete! You can now clone repos using SSH."