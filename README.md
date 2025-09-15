# Dotfiles Bootstrap (macOS / Apple Silicon)

Minimal, opinionated Mac setup: install core tools, link dotfiles, apply a few sane defaults, configure shell + VS Code.

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
