# Dotfiles Bootstrap (macOS / Apple Silicon)

Minimal, opinionated Mac setup: install core tools, link dotfiles, apply a few sane defaults, configure shell + VS Code.

## What I Change on a New Mac
A quick reference you can follow **by hand**, no scripts needed. Paths are for current macOS (System Settings). If you do use this repo, `./new_mac_defaults.sh` applies everything tagged with a `[group]`.

### Finder
- **Show path bar and status bar** — Finder → View → Show Path Bar / Show Status Bar `[finder]`
- **Show all filename extensions** — Finder → Settings… → Advanced `[finder]`
- **Don't warn when changing an extension** — Finder → Settings… → Advanced `[finder]`
- **Keep folders on top** (when sorting by name) — Finder → Settings… → Advanced `[finder]`
- **Search the current folder, not the whole Mac** — Finder → Settings… → Advanced → "When performing a search" `[finder]`
- **Show the Library folder** — Go → Home, then View → Show View Options → Show Library Folder `[finder]`

### Keyboard & typing
- **Key repeat rate: Fast; Delay until repeat: short** — System Settings → Keyboard `[keyboard]`
- **Keyboard navigation on** (Tab moves between buttons in dialogs) — System Settings → Keyboard → Keyboard navigation
- **Turn off auto-correct, smart quotes/dashes, double-space period** — System Settings → Keyboard → Text Input → Input Sources → Edit… `[typing]`. Essential if you ever type code or commands.

### Screenshots
- **Swap the "save to file" and "copy to clipboard" shortcuts** so ⇧⌘4 copies to the clipboard (paste anywhere) — System Settings → Keyboard → Keyboard Shortcuts… → Screenshots
- **Save to a `~/Screenshots` folder** instead of the Desktop — press ⇧⌘5 → Options → Save to → Other Location… `[screenshots]`
- **No drop shadow on window captures** — hold ⌥ while clicking the window, or make it permanent with the Terminal command below `[screenshots]`

### Desktop & Dock
- **Minimize using Scale effect** (faster than Genie) — System Settings → Desktop & Dock `[dock]`
- **Minimize windows into application icon** (keeps the Dock tidy) — System Settings → Desktop & Dock `[dock]`
- **Hide suggested and recent apps in Dock** — System Settings → Desktop & Dock `[dock]`

### Trackpad
- **Tap to click** — System Settings → Trackpad → Point & Click `[trackpad]`
- **App Exposé: three-finger swipe down** — System Settings → Trackpad → More Gestures `[trackpad]`

### Apps
- **TextEdit: plain text by default, UTF-8** — TextEdit → Settings… → New Document → Plain text; Open and Save → encoding UTF-8 `[textedit]`
- **Activity Monitor: show all processes, sort by CPU** — View → All Processes, then click the "% CPU" column `[activitymonitor]`

### No checkbox for these (Terminal one-liners)
```bash
# Don't create .DS_Store files on network shares and USB drives
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
# Open save and print dialogs expanded
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
# No shadow on window screenshots
defaults write com.apple.screencapture disable-shadow -bool true && killall SystemUIServer
```

### What I install
Everything below comes from Homebrew (full list in [`Brewfile`](Brewfile)) unless noted.
- **Mac utilities:** Rectangle (window snapping), Raycast (Spotlight replacement), Hidden Bar (tidy menu bar), Tailscale
- **Terminal & editors:** iTerm2, VS Code, Sublime Text, Neovim, Obsidian, plus Oh My Zsh with zsh-autosuggestions and syntax highlighting
- **Browsers:** Arc, Firefox, Chrome, Edge, Tor Browser
- **Dev:** `gh`, `uv`, pyenv, rustup, Docker Desktop, DBeaver, Android Studio, gcloud CLI
- **AI:** Claude, ChatGPT, Ollama
- **Everyday:** Discord, Telegram, Zoom, Spotify, VLC
- **Media & home:** OBS, HandBrake, Plex, Jellyfin, Philips Hue Sync
- **Audio & desk gear:** Reaper, Focusrite Control, Mixing Station, Elgato Stream Deck, Logi Options+
- **Outside Homebrew:** Microsoft 365, DaVinci Resolve, Softube Central / iLok (audio plugins).

Placeholder tokens present until you personalize: `YOUR_GITHUB_USERNAME`, `YOUR_NAME`, `YOUR_EMAIL@example.com`.

## TL;DR – Fresh Mac
1. (Optional) Personalize repo placeholders:
   ```bash
   git clone https://github.com/YOUR_GITHUB_USERNAME/dotfiles.git ~/dotfiles && cd ~/dotfiles
   ./personalize.sh --github myuser --name "My Name" --email me@example.com
   ```
2. Run setup (review first):
   ```bash
   ./my_mac_setup.sh
   ```
3. Open a new terminal (loads zsh + brew env) and launch VS Code once.
4. (Optional) Apply macOS tweaks later:
   ```bash
   ./new_mac_defaults.sh apply
   ```

## Or: One-Liner (clone + personalize + run)
Fetches the latest `bootstrap.sh`, clones this repo (if missing), optionally prompts for your GitHub/name/email to replace placeholders, then launches the main setup.
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/bwooceli/dotfiles/main/bootstrap.sh)"
```
Append flags after the closing quote to skip pieces passed through to `my_mac_setup.sh` (see Advanced doc):
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/bwooceli/dotfiles/main/bootstrap.sh)" --no-defaults --no-vscode
```
Disable the personalization prompt (if you want to do it manually later):
```bash
DOTFILES_NO_PERSONALIZE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/bwooceli/dotfiles/main/bootstrap.sh)"
```

## What You Get (Default Run)
- Xcode CLT (only if missing)
- Homebrew + packages from `Brewfile`
- Oh My Zsh (if missing)
- Symlinks: `.zshrc`, `.aliases`, `.gitignore`, VS Code settings, optional `.gitconfig`
- Optional macOS defaults (if not skipped)

Re-running is safe: linking + installs are idempotent; existing real files are timestamp‑backed up before linking.

## Quick Checks
```bash
./doctor.sh        # verifies brew, oh-my-zsh, symlinks, VS Code settings
```

## Update Later
```bash
git -C ~/dotfiles pull
brew bundle --file ~/dotfiles/Brewfile
```

## Customize Identity Later
If you had an existing `~/.gitconfig` it is not replaced. To apply the repo version, move or remove yours then re-run setup.

Replace placeholders anytime:
```bash
cd ~/dotfiles
./personalize.sh --github myuser --name "My Name" --email me@example.com
```

## Need More Detail?
Flags, sandbox testing, granular defaults groups, roadmap, rollback steps, and security notes live in: **`ADVANCED.md`**.

---
For a deeper dive: open `ADVANCED.md`. Otherwise you're done.
