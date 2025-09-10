#!/usr/bin/env bash
# Minimal bash profile (primary shell assumed zsh). Sources shared aliases & optional nvm lazily.

# Lazy-load nvm only when node is invoked
load_nvm() {
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm
    [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
}

command -v node >/dev/null 2>&1 || load_nvm

# Shared aliases
[ -f "$HOME/.aliases" ] && source "$HOME/.aliases"

export PATH="$HOME/bin:$PATH"

HISTSIZE=5000
HISTFILESIZE=10000
shopt -s histappend

# Simple prompt
PS1="\u@\h \w$ "
