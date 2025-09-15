# Advanced Usage & Reference

This file contains the deeper details pulled out of the main `README.md` so first‑time setup stays simple.

## Script Flags (All)
```
--no-brew       Skip Homebrew install & bundle
--no-dotfiles   Skip linking dotfiles
--no-omz        Skip Oh My Zsh install
--no-vscode     Skip VS Code settings link
--no-defaults   Skip macOS defaults script
--dry-run       Show actions only
--force         Overwrite existing backups silently
```
Idempotent: you can safely re-run `./my_mac_setup.sh` with different flags.

## What Gets Installed
1. Xcode Command Line Tools (if missing)
2. Homebrew (if missing)
3. Brew packages & casks from `Brewfile`
4. Oh My Zsh (non-interactive) if absent
5. Symlinks to: `.zshrc`, `.aliases`, `.gitignore`, VS Code settings, (only) `.gitconfig` if you don't already have one
6. Optional macOS defaults via `new_mac_defaults.sh`

## macOS Defaults Script
Apply everything:
```bash
./new_mac_defaults.sh apply
```
Dry run first:
```bash
./new_mac_defaults.sh apply --dry-run
```
List groups:
```bash
./new_mac_defaults.sh list
```
Apply only one group (example):
```bash
./new_mac_defaults.sh apply dock
```
Groups implemented: finder, textedit, keyboard, dock, trackpad.

## Doctor (Health Check)
```bash
./doctor.sh
```
Returns non-zero exit if a required piece is missing.

## Personalizing Placeholders
Tokens: `YOUR_GITHUB_USERNAME`, `YOUR_NAME`, `YOUR_EMAIL@example.com`.
```bash
./personalize.sh --github myuser --name "My Name" --email me@example.com
```
Dry run:
```bash
./personalize.sh --github myuser --name "My Name" --email me@example.com --dry-run
```

## Testing In a Sandbox (Fake Home)
```bash
mkdir -p /tmp/dotfiles-sandbox
export DOTFILES_TARGET_HOME=/tmp/dotfiles-sandbox
rm -rf /tmp/dotfiles-sandbox/*
./my_mac_setup.sh --dry-run --no-brew --no-defaults
./my_mac_setup.sh --no-brew --no-defaults --no-omz
HOME=$DOTFILES_TARGET_HOME ./doctor.sh
```
Notes:
* Brew + defaults still hit the real system; skip them for safe tests.
* Script honors `DOTFILES_TARGET_HOME` for linking & `.zprofile` only.
* For full isolation use a VM or a separate macOS user account.

## Updating After Initial Install
```bash
git -C ~/dotfiles pull
brew bundle --file ~/dotfiles/Brewfile
```

## VS Code Settings
The repo's `vs_code.user.settings.json` is symlinked into the standard user settings path. Change it in the repo to version control adjustments.

## Manual System Settings Tweaks (Reference)
Finder: path view, folders on top
Keyboard: fast repeat, medium-short delay, enable keyboard navigation, disable smart quotes, swap screenshot shortcuts
Desktop & Dock: Scale minimize, minimize-to-application, hide recents
Trackpad: Tap to click, App Exposé three-finger down

## Capturing Additional macOS Defaults Yourself
```
cp -r /Library/Preferences before
# change a setting
cp -r /Library/Preferences after
diff -ur before after | less
```
Look for relevant domain keys to add to `new_mac_defaults.sh` groups.

## Security Notes
Review scripts before running. Remote installers (Homebrew, Oh My Zsh) are fetched over HTTPS. Pin commits if you need stronger supply-chain guarantees.

## Rollback / Uninstall (Manual)
Remove created symlinks and restore `*.backup.<timestamp>` files. Some defaults require manual revert in System Settings.

## Roadmap Ideas
* Split `Brewfile` into core vs personal
* Add CI (shellcheck + brew bundle check)
* Optional templated `.gitconfig` prompt

---
Return to simplified instructions: see `README.md`.
