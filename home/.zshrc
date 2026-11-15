# ~/.zshrc — managed by ~/dotfiles (see install.sh). Machine-specific bits go in ~/.zshrc.local.

# Source a file only if it exists, so a fresh machine doesn't spew errors.
source_if() { if [ -f "$1" ]; then source "$1"; fi; }

# ---------------------------------------------------------------------------
# oh-my-zsh
# ---------------------------------------------------------------------------
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git dotenv)
source_if "$ZSH/oh-my-zsh.sh"

# ---------------------------------------------------------------------------
# Environment
# ---------------------------------------------------------------------------
export EDITOR="nvim"
export KUBE_EDITOR="nano -w"

# uv / pipx-style tools in ~/.local/bin
source_if "$HOME/.local/bin/env"

# pnpm
if [[ "$OSTYPE" == darwin* ]]; then
  export PNPM_HOME="$HOME/Library/pnpm"
else
  export PNPM_HOME="$HOME/.local/share/pnpm"
fi
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# Google Cloud SDK (manual install in ~/google-cloud-sdk, or the Homebrew cask)
if [ -d "$HOME/google-cloud-sdk" ]; then
  source_if "$HOME/google-cloud-sdk/path.zsh.inc"
  source_if "$HOME/google-cloud-sdk/completion.zsh.inc"
elif command -v brew >/dev/null && [ -d "$(brew --prefix)/share/google-cloud-sdk" ]; then
  source_if "$(brew --prefix)/share/google-cloud-sdk/path.zsh.inc"
  source_if "$(brew --prefix)/share/google-cloud-sdk/completion.zsh.inc"
fi

# Nebius CLI
source_if "$HOME/.nebius/path.zsh.inc"

# OpenClaw completion
source_if "$HOME/.openclaw/completions/openclaw.zsh"

# ---------------------------------------------------------------------------
# Aliases
# ---------------------------------------------------------------------------
alias vim="nvim"
alias cdantioch="cd ~/Documents/Work/antioch/code.nosync/antioch-monorepo/"
alias cdantioch2="cd ~/Documents/Work/antioch/code.nosync/antioch-monorepo2/"

# ---------------------------------------------------------------------------
# atuin (shell history) — keep near the end so its keybindings win
# ---------------------------------------------------------------------------
source_if "$HOME/.atuin/bin/env"
command -v atuin >/dev/null && eval "$(atuin init zsh)"

# Machine-specific overrides and secrets (not tracked)
source_if "$HOME/.zshrc.local"
