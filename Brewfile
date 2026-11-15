# Brewfile — `brew bundle` reads this. install.sh sets these env vars from your answers:
#   DOTFILES_BREW_CLI=1   developer CLI tools (infra, databases, languages)
#   DOTFILES_BREW_APPS=1  GUI apps (macOS only)
# The "core" section always installs — the dotfiles themselves depend on it.

cli  = ENV["DOTFILES_BREW_CLI"] == "1"
apps = ENV["DOTFILES_BREW_APPS"] == "1" && OS.mac?

# --- core -------------------------------------------------------------------
brew "git"
brew "gh"
brew "atuin"
brew "neovim"
brew "tmux"
brew "ripgrep"
brew "python"  # latest python3 — .zprofile puts it first on PATH
brew "uv"
brew "pnpm"
brew "pre-commit"
brew "wget"
brew "coreutils"
brew "bash"
brew "watch"
brew "just"
brew "mosh"

if cli
  tap "hashicorp/tap"

  # languages & runtimes
  brew "node@22"
  brew "python@3.11"
  brew "pyenv"
  brew "rustup"
  brew "openjdk"

  # infra & cloud
  brew "hashicorp/tap/terraform"
  brew "terragrunt"
  brew "tflint"
  brew "tfsec"
  brew "helm"
  brew "kompose"
  brew "step"
  brew "mkcert"
  brew "nss"

  # databases
  brew "postgresql@14"
  brew "mysql"
  brew "redis"

  # misc
  brew "git-lfs"
  brew "gemini-cli"
  brew "pandoc"
  brew "graphviz"
  brew "ghostscript"
  brew "keyring"
  brew "flock"
  brew "dependency-check"

  cask "claude-code"
  cask "1password-cli"
  cask "gcloud-cli"
end

if apps
  # browsers
  cask "arc"
  cask "google-chrome"
  cask "firefox"
  cask "brave-browser"

  # dev
  cask "cursor"
  cask "visual-studio-code"
  cask "zed"
  cask "warp"
  cask "iterm2"
  cask "docker-desktop"
  cask "dbeaver-community"
  cask "postman"
  cask "tailscale-app"

  # AI
  cask "claude"
  cask "chatgpt"
  cask "wispr-flow"
  cask "granola"

  # productivity & comms
  cask "1password"
  cask "notion"
  cask "notion-calendar"
  cask "obsidian"
  cask "linear-linear"
  cask "superhuman"
  cask "slack"
  cask "zoom"
  cask "loom"
  cask "signal"
  cask "telegram"
  cask "whatsapp"
  cask "discord"

  # media & utilities
  cask "spotify"
  cask "vlc"
  cask "obs"
  cask "logi-options+"
  cask "cameracontroller"
  cask "yed"
end
