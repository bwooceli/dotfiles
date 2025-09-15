# Dotfiles Bootstrap

Apple Silicon focused, opinionated setup for a fresh macOS environment. Installs core tools, links dotfiles via symlinks, applies selected macOS defaults, and configures shell + VS Code.

> NOTE: This repository contains placeholder tokens: `YOUR_GITHUB_USERNAME`, `YOUR_NAME`, `YOUR_EMAIL@example.com`.
> Run `./personalize.sh` to replace them with your real identity before sharing or committing.

## Quickstart (Review First!)

Clone and run locally (safer than piping remote script):

```bash
git clone https://github.com/YOUR_GITHUB_USERNAME/dotfiles.git ~/dotfiles
cd ~/dotfiles
./my_mac_setup.sh
```

### One-Liner (Fast Start / Fresh Mac)
If you really want a single command (e.g., brand new Mac without git cloned repo yet):
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/YOUR_GITHUB_USERNAME/dotfiles/main/bootstrap.sh)"
```
You can pass flags through:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/YOUR_GITHUB_USERNAME/dotfiles/main/bootstrap.sh)" --no-defaults --no-vscode
```
The one-liner will:
1. Trigger Xcode CLT install if missing (and stop for you to finish it)
2. Download repo (git if available; tarball fallback if not)
3. Install Homebrew if missing
4. Run `my_mac_setup.sh` with any extra flags you supplied

### Making Scripts Executable
If you clone manually, ensure scripts are executable (usually preserved):
```bash
chmod +x my_mac_setup.sh new_mac_defaults.sh doctor.sh bootstrap.sh
```

Optional flags:
```
  --no-brew       Skip Homebrew + bundle
  --no-dotfiles   Skip linking dotfiles
  --no-omz        Skip Oh My Zsh install
  --no-vscode     Skip VS Code settings link
  --no-defaults   Skip macOS defaults script
  --dry-run       Show actions only
  --force         Overwrite existing backups silently
```

Re-run safe: script is idempotent. Backups are created with a timestamp if original non-symlink files exist.

## What Gets Installed

1. Xcode Command Line Tools (if missing)
2. Homebrew (if missing)
3. Brew packages & casks from `Brewfile`
4. Oh My Zsh (non-interactive) if absent
5. Symlinks to: `.zshrc`, `.aliases`, `.gitignore`, VS Code settings, (optional) `.gitconfig`
6. Optional macOS defaults via `new_mac_defaults.sh`

## macOS Defaults

Apply all defaults:
```bash
./new_mac_defaults.sh apply
```
Dry run:
```bash
./new_mac_defaults.sh apply --dry-run
```
List groups:
```bash
./new_mac_defaults.sh list
```

## Doctor (Health Check)
```bash
./doctor.sh
```

## Testing Changes (Without Touching Your Real Home)

You can simulate a "fresh" environment locally:

```bash
# Create a sandbox directory to act as a fake home
mkdir -p /tmp/dotfiles-sandbox
export DOTFILES_TARGET_HOME=/tmp/dotfiles-sandbox

# (Optional) remove any prior state
rm -rf /tmp/dotfiles-sandbox/*

# Dry run first
./my_mac_setup.sh --dry-run --no-brew --no-defaults

# Execute selected parts (skip brew for speed, still links into sandbox)
./my_mac_setup.sh --no-brew --no-defaults --no-omz

# Inspect results
tree /tmp/dotfiles-sandbox -L 2

# Run doctor against sandbox by temporarily adjusting HOME
HOME=$DOTFILES_TARGET_HOME ./doctor.sh
```

Notes:
* Brew & defaults still operate on the real system; use `--no-brew --no-defaults` for safe sandbox tests.
* The script now honors `DOTFILES_TARGET_HOME` for linking dotfiles & writing `.zprofile`.
* For full isolation, test in a macOS VM (UTM/VirtualBuddy) or a fresh user account.

## Updating
```bash
git -C ~/dotfiles pull
brew bundle --file ~/dotfiles/Brewfile
```

## Git Identity
If you already have a global `~/.gitconfig`, the setup script will not overwrite it. Edit manually or remove then re-run if you want the repo version.

To replace placeholders in this repo:
```bash
./personalize.sh --github myuser --name "My Name" --email me@example.com
```
Dry run first:
```bash
./personalize.sh --github myuser --name "My Name" --email me@example.com --dry-run
```

## VS Code Settings
Linked into the user settings location. Modify the repo file to version-control changes.

## Security & Trust
Review scripts before execution. Remote install scripts (Homebrew, Oh My Zsh) are fetched via HTTPS; consider pinning revisions if supply-chain risk is a concern.

## Uninstall / Rollback (Manual)
Remove symlinks and restore backups created alongside (e.g. `.zshrc.backup.<timestamp>`). Some macOS defaults may require manual reset via System Settings.

## Roadmap / Ideas
* Split Brewfile into core vs personal layers
* Add CI (shellcheck + brew bundle check)
* Template-based `.gitconfig` with on-demand prompt

---

## Main Settings to Change
  
Settings
 * Finder Settings (not system)
    * Enable path view
    * Keep folders on top
 * Keyboard
    * Key repeat rate = Fast
    * Delay until repeat = 4 (Med-Short)
    * Enable Keyboard Navigation
    * Input Sources -> disable smart quotes
    * Swap the shortcut for "Screenshot to File" and "Screenshot to Clipboard"
 * Desktop and Dock
    * Change "Minimize Using" to "Scale"
    * Enable Minimize windows into application icon
    * Disabled "Recommended and Recent" apps in docker
    * Trackpad
      * Enable Tap to Click
      * More Gestures -> Enable App Expose with three finger down-swipe


# Other Apps installed outside of Brew
 * Microsoft 365
 * DaVinci Resolve
 * SoftTube Central / iLok (vsts)

## Capturing Additional Defaults (Manual Technique)
```
cp -r /Library/Preferences before
# change a setting
cp -r /Library/Preferences after
diff -ur before after | less
```
Look for relevant domain keys to add to `new_mac_defaults.sh`.
