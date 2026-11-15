#!/usr/bin/env bash
#
# Harry's dotfiles installer.
#
# Fresh machine (clones the repo to ~/.dotfiles, then runs from there):
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/HarryMellsop/dotfiles/master/install.sh)"
#
# From a checkout:
#   ./install.sh               interactive full setup
#   ./install.sh --yes         accept every default, no questions
#   ./install.sh --links-only  just (re)link dotfiles — handy after a git pull
#   ./install.sh --dry-run     show what would happen, change nothing
#
# Safe to re-run: every step checks before acting, and anything it would
# overwrite is moved to ~/.dotfiles-backup/<timestamp>/ first.

set -euo pipefail

REPO_URL="https://github.com/HarryMellsop/dotfiles.git"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
LOG="$HOME/.dotfiles-install.log"
TILDE="~"  # pretty paths: ${p/#$HOME/$TILDE} (a bare ~ gets re-expanded by bash 5)

YES=0 DRY=0 LINKS_ONLY=0 NO_BREW=0 CONTINUED=0

usage() {
  sed -n '3,15p' "$0" 2>/dev/null | sed 's/^# \{0,1\}//'
  cat <<EOF

Options:
  -y, --yes         Non-interactive; accept defaults (CLI tools + apps, skip logins)
  -n, --dry-run     Print the plan without changing anything
  -l, --links-only  Only link dotfiles and seed app configs
      --no-brew     Skip Homebrew and the Brewfile entirely
  -h, --help        Show this help

Env:
  DOTFILES_DIR      Where to clone on a fresh machine (default: ~/.dotfiles)
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    -y|--yes) YES=1 ;;
    -n|--dry-run) DRY=1 ;;
    -l|--links-only) LINKS_ONLY=1 ;;
    --no-brew) NO_BREW=1 ;;
    --_continued) CONTINUED=1 ;;  # internal: bootstrap handed off to the clone
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
  shift
done

# ---------------------------------------------------------------------------
# UI
# ---------------------------------------------------------------------------
if [ -t 1 ]; then
  BOLD=$'\033[1m' DIM=$'\033[2m' RED=$'\033[31m' GREEN=$'\033[32m'
  YELLOW=$'\033[33m' BLUE=$'\033[34m' MAGENTA=$'\033[35m' CYAN=$'\033[36m' RESET=$'\033[0m'
else
  BOLD="" DIM="" RED="" GREEN="" YELLOW="" BLUE="" MAGENTA="" CYAN="" RESET=""
fi

STEP=0 TOTAL=0
step() { STEP=$((STEP + 1)); printf "\n${BOLD}${BLUE}[%d/%d]${RESET} ${BOLD}%s${RESET}\n" "$STEP" "$TOTAL" "$1"; }
ok()   { printf "  ${GREEN}✓${RESET} %s\n" "$1"; }
info() { printf "  ${CYAN}•${RESET} %s\n" "$1"; }
skip() { printf "  ${DIM}– %s${RESET}\n" "$1"; }
warn() { printf "  ${YELLOW}!${RESET} %s\n" "$1"; WARNINGS="${WARNINGS:-}  ${YELLOW}!${RESET} $1"$'\n'; }
die()  { printf "\n  ${RED}✗ %s${RESET}\n\n" "$1" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

# ask "Question?" y|n  -> returns 0 for yes. Reads from the terminal even under curl|bash.
ask() {
  local prompt=$1 default=$2 hint reply
  if [ "$default" = y ]; then hint="Y/n"; else hint="y/N"; fi
  if [ "$YES" = 1 ] || [ ! -r /dev/tty ]; then
    [ "$default" = y ]; return
  fi
  printf "  ${MAGENTA}?${RESET} %s ${DIM}[%s]${RESET} " "$prompt" "$hint"
  read -r reply </dev/tty || reply=""
  reply=$(printf '%s' "$reply" | tr '[:upper:]' '[:lower:]')
  case "${reply:-$default}" in y|yes) return 0 ;; *) return 1 ;; esac
}

# run "Message" cmd args...  — runs quietly with a spinner, output goes to $LOG.
run() {
  local msg=$1; shift
  if [ "$DRY" = 1 ]; then info "${DIM}would run:${RESET} $*"; return 0; fi
  printf '\n### %s\n$ %s\n' "$msg" "$*" >>"$LOG"
  "$@" >>"$LOG" 2>&1 &
  local pid=$! i=0 rc=0
  local frames=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)
  if [ -t 1 ]; then
    while kill -0 "$pid" 2>/dev/null; do
      printf "\r  ${CYAN}%s${RESET} %s" "${frames[i++ % 10]}" "$msg"
      sleep 0.1
    done
    printf "\r\033[K"
  fi
  wait "$pid" || rc=$?
  if [ "$rc" = 0 ]; then ok "$msg"; else
    printf "  ${RED}✗${RESET} %s ${DIM}(exit %d — last lines of %s:)${RESET}\n" "$msg" "$rc" "$LOG"
    tail -n 8 "$LOG" | sed "s/^/      ${DIM}/;s/\$/${RESET}/"
  fi
  return "$rc"
}

# Like run, but in the foreground for things that may prompt (sudo, logins).
run_fg() {
  if [ "$DRY" = 1 ]; then info "${DIM}would run:${RESET} $*"; return 0; fi
  "$@"
}

# ---------------------------------------------------------------------------
# Locate (or fetch) the repo
# ---------------------------------------------------------------------------
OS=$(uname -s)
case "$OS" in Darwin) IS_MAC=1 ;; Linux) IS_MAC=0 ;; *) die "Unsupported OS: $OS" ;; esac

SCRIPT_DIR=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
  SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
fi
if [ -n "$SCRIPT_DIR" ] && [ -d "$SCRIPT_DIR/home" ]; then
  DOTFILES=$SCRIPT_DIR BOOTSTRAP=0
else
  DOTFILES=${DOTFILES_DIR:-$HOME/.dotfiles} BOOTSTRAP=1
fi

# ---------------------------------------------------------------------------
# Steps
# ---------------------------------------------------------------------------
xcode_clt() {
  step "Xcode Command Line Tools"
  if xcode-select -p >/dev/null 2>&1; then ok "already installed"; return; fi
  [ "$DRY" = 1 ] && { info "would run: xcode-select --install"; return; }
  xcode-select --install >/dev/null 2>&1 || true
  info "Finish the installer dialog that just popped up — waiting for it…"
  until xcode-select -p >/dev/null 2>&1; do sleep 5; done
  ok "installed"
}

clone_repo() {
  step "Fetching dotfiles"
  if [ "$BOOTSTRAP" = 0 ]; then ok "using checkout at ${DOTFILES/#$HOME/$TILDE}"; return; fi
  if [ -d "$DOTFILES/.git" ]; then
    run "Updating ${DOTFILES/#$HOME/$TILDE}" git -C "$DOTFILES" pull --ff-only || warn "couldn't fast-forward $DOTFILES; using it as-is"
  else
    have git || die "git is required (install Xcode CLT or your distro's git package)"
    run "Cloning into ${DOTFILES/#$HOME/$TILDE}" git clone "$REPO_URL" "$DOTFILES" || die "clone failed"
  fi
  [ "$DRY" = 1 ] && [ ! -d "$DOTFILES" ] && { info "dry run on a fresh machine: stopping here"; exit 0; }
  # Hand off to the checked-out copy so the rest runs from the repo's own (latest) script.
  exec bash "$DOTFILES/install.sh" "${ORIG_ARGS[@]+"${ORIG_ARGS[@]}"}" --_continued
}

homebrew() {
  step "Homebrew"
  if ! have brew; then
    for b in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
      [ -x "$b" ] && eval "$("$b" shellenv)" && break
    done
  fi
  if have brew; then ok "found $(brew --version | head -1)"; else
    if [ "$IS_MAC" = 0 ] && ! ask "Homebrew isn't installed. Install Linuxbrew?" n; then
      skip "skipping Homebrew"; NO_BREW=1; return
    fi
    info "Installing Homebrew (it will ask for your password)…"
    run_fg /bin/bash -c '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    for b in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
      [ -x "$b" ] && eval "$("$b" shellenv)" && break
    done
    [ "$DRY" = 1 ] || have brew || die "Homebrew install failed"
    ok "Homebrew installed"
  fi

  local what="core"
  [ "$WANT_CLI" = 1 ] && what="$what + CLI tools"
  [ "$WANT_APPS" = 1 ] && what="$what + apps"
  info "brew bundle ($what) — this is the long part"
  export DOTFILES_BREW_CLI=$WANT_CLI DOTFILES_BREW_APPS=$WANT_APPS
  if run_fg brew bundle --file="$DOTFILES/Brewfile"; then
    ok "Brewfile installed"
  else
    warn "some Brewfile entries failed — re-run: brew bundle --file=$DOTFILES/Brewfile"
  fi
}

oh_my_zsh() {
  step "oh-my-zsh"
  if [ -d "$HOME/.oh-my-zsh" ]; then ok "already installed"; return; fi
  have zsh || { warn "zsh not found; skipping oh-my-zsh"; return; }
  run "Installing oh-my-zsh" env ZSH="$HOME/.oh-my-zsh" RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c 'curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | sh' \
    || warn "oh-my-zsh install failed"
}

link_one() {  # link_one <repo path> <target path>
  local src=$1 dest=$2 pretty=${2/#$HOME/$TILDE}
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    skip "$pretty"; return
  fi
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    local rel=${dest#"$HOME"/}
    if [ "$DRY" = 1 ]; then
      info "$pretty ${DIM}(would back up existing, then link)${RESET}"; return
    fi
    mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
    mv "$dest" "$BACKUP_DIR/$rel"
    BACKED_UP=$((BACKED_UP + 1))
    ok "$pretty ${DIM}(old one backed up)${RESET}"
  else
    [ "$DRY" = 1 ] && { info "$pretty ${DIM}(would link)${RESET}"; return; }
    ok "$pretty"
  fi
  mkdir -p "$(dirname "$dest")"
  ln -s "$src" "$dest"
}

link_dotfiles() {
  step "Linking dotfiles → ~"
  BACKED_UP=0
  local f
  while IFS= read -r -d '' f; do
    link_one "$f" "$HOME/${f#"$DOTFILES/home/"}"
  done < <(find "$DOTFILES/home" -mindepth 1 \( -type f -o -type l \) -not -name .DS_Store -print0 | sort -z)
  [ "$BACKED_UP" -gt 0 ] && info "$BACKED_UP file(s) backed up to ${BACKUP_DIR/#$HOME/$TILDE}"
  true
}

seed_configs() {
  # Apps that rewrite their own config files get a one-time copy instead of a symlink.
  step "Seeding app configs (copied once, never overwritten)"
  local f dest pretty
  while IFS= read -r -d '' f; do
    dest="$HOME/${f#"$DOTFILES/seed/"}" pretty=${dest/#$HOME/$TILDE}
    if [ ! -e "$dest" ]; then
      if [ "$DRY" = 1 ]; then info "$pretty ${DIM}(would copy)${RESET}"; else
        mkdir -p "$(dirname "$dest")" && cp "$f" "$dest" && ok "$pretty"
      fi
    elif cmp -s "$f" "$dest"; then
      skip "$pretty"
    else
      skip "$pretty exists and differs — left alone (diff \"$f\" \"$dest\")"
    fi
  done < <(find "$DOTFILES/seed" -type f -not -name .DS_Store -print0 | sort -z)
}

plugins() {
  step "Shell & editor plugins"

  # bash-preexec, so atuin works in bash too
  if [ -f "$HOME/.bash-preexec.sh" ]; then skip "bash-preexec"; else
    run "bash-preexec" curl -fsSL -o "$HOME/.bash-preexec.sh" \
      https://raw.githubusercontent.com/rcaloras/bash-preexec/master/bash-preexec.sh || warn "bash-preexec download failed"
  fi

  # atuin (normally from the Brewfile; fall back to the official installer)
  if have atuin || [ -x "$HOME/.atuin/bin/atuin" ]; then skip "atuin"; else
    run "atuin" sh -c "curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh -s -- --no-modify-path" \
      || warn "atuin install failed"
  fi

  # tmux plugins: clone everything declared with `set -g @plugin` (tpm itself included).
  # (tpm's own install_plugins needs a live tmux server, so we skip it.)
  if have tmux; then
    local plugin name
    for plugin in $(sed -n "s/^set -g @plugin '\(.*\)'.*/\1/p" "$DOTFILES/home/.tmux.conf"); do
      name=${plugin##*/}
      if [ -d "$HOME/.tmux/plugins/$name" ]; then skip "tmux: $name"; else
        run "tmux: $name" git clone --depth 1 "https://github.com/$plugin" "$HOME/.tmux/plugins/$name" \
          || warn "tmux plugin $plugin failed — press prefix + I inside tmux"
      fi
    done
  else
    skip "tmux not installed — skipping plugins"
  fi

  # vim-plug + plugins (YouCompleteMe compiles, so this can take a few minutes)
  if have nvim; then
    local plug="$HOME/.local/share/nvim/site/autoload/plug.vim"
    [ -f "$plug" ] || run "vim-plug" curl -fsSLo "$plug" --create-dirs \
      https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim || warn "vim-plug download failed"
    run "neovim plugins (YouCompleteMe compiles — be patient)" \
      nvim --headless "+PlugInstall --sync" +qa \
      || warn "some nvim plugins failed — open nvim and run :PlugInstall"
  else
    skip "neovim not installed — skipping plugins"
  fi
}

accounts() {
  step "Accounts"
  if [ "$YES" = 1 ]; then skip "--yes: skipping logins (gh auth login, atuin login)"; return; fi

  if have gh; then
    if gh auth status >/dev/null 2>&1; then ok "GitHub CLI logged in"
    elif ask "Log in to GitHub (gh auth login)?" y; then
      run_fg gh auth login && ok "GitHub CLI logged in" || warn "gh auth login didn't complete"
    else skip "GitHub — run 'gh auth login' later"; fi
  fi

  local atuin_bin=""
  if have atuin; then atuin_bin=atuin; elif [ -x "$HOME/.atuin/bin/atuin" ]; then atuin_bin="$HOME/.atuin/bin/atuin"; fi
  if [ -n "$atuin_bin" ]; then
    if "$atuin_bin" status >/dev/null 2>&1; then ok "atuin sync logged in"
    else
      info "atuin sync needs your username, password and encryption key."
      info "Get the key on your old machine with: ${BOLD}atuin key${RESET}"
      if ask "Log in to atuin sync now?" n; then
        if run_fg "$atuin_bin" login; then
          run "Syncing shell history" "$atuin_bin" sync || warn "atuin sync failed"
        else warn "atuin login didn't complete — run 'atuin login' later"; fi
      else skip "atuin — run 'atuin login' then 'atuin sync' later"; fi
    fi
  fi

  if [ "$(basename "${SHELL:-}")" != zsh ] && have zsh; then
    if ask "Make zsh your default shell?" y; then
      run_fg chsh -s "$(command -v zsh)" && ok "default shell is now zsh" || warn "chsh failed"
    fi
  fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
ORIG_ARGS=()
[ "$YES" = 1 ] && ORIG_ARGS+=(--yes)
[ "$DRY" = 1 ] && ORIG_ARGS+=(--dry-run)
[ "$LINKS_ONLY" = 1 ] && ORIG_ARGS+=(--links-only)
[ "$NO_BREW" = 1 ] && ORIG_ARGS+=(--no-brew)

main() {
  printf "\n${BOLD}  ✦ dotfiles${RESET} ${DIM}— %s, %s%s${RESET}\n" \
    "$([ "$IS_MAC" = 1 ] && echo macOS || echo Linux)" "${DOTFILES/#$HOME/$TILDE}" \
    "$([ "$DRY" = 1 ] && echo ', DRY RUN' || true)"

  if [ "$LINKS_ONLY" = 1 ]; then
    TOTAL=2; link_dotfiles; seed_configs
    printf "\n${GREEN}${BOLD}  Done.${RESET} Open a new shell to pick up changes.\n\n"
    return
  fi

  # Ask everything up front so the long part can run unattended.
  WANT_CLI=${DOTFILES_WANT_CLI:-0} WANT_APPS=${DOTFILES_WANT_APPS:-0}
  if [ "$NO_BREW" = 0 ] && [ "$CONTINUED" = 0 ]; then
    printf "\n  ${DIM}A few questions first, then you can walk away.${RESET}\n"
    ask "Install developer CLI tools (terraform, helm, postgres, node, …)?" y && WANT_CLI=1
    [ "$IS_MAC" = 1 ] && ask "Install GUI apps (Arc, Cursor, Slack, Notion, 1Password, …)?" y && WANT_APPS=1
    true
  fi
  export DOTFILES_WANT_CLI=$WANT_CLI DOTFILES_WANT_APPS=$WANT_APPS
  # A sudo prompt now keeps cask installers from stalling later.
  if [ "$IS_MAC" = 1 ] && [ "$NO_BREW" = 0 ] && [ "$DRY" = 0 ] && [ "$CONTINUED" = 0 ]; then
    info "Caching sudo for installers that need it…"
    sudo -v </dev/tty || true
  fi

  if [ "$BOOTSTRAP" = 1 ]; then
    TOTAL=2; [ "$IS_MAC" = 1 ] && xcode_clt; clone_repo   # re-execs from the clone
  fi

  TOTAL=6; [ "$IS_MAC" = 1 ] && TOTAL=$((TOTAL + 1)); [ "$NO_BREW" = 1 ] && TOTAL=$((TOTAL - 1))
  [ "$IS_MAC" = 1 ] && xcode_clt
  [ "$NO_BREW" = 0 ] && homebrew
  oh_my_zsh
  link_dotfiles
  seed_configs
  plugins
  accounts

  printf "\n${GREEN}${BOLD}  ✦ All set.${RESET}\n"
  if [ -n "${WARNINGS:-}" ]; then printf "\n  ${BOLD}Needs attention:${RESET}\n%s" "$WARNINGS"; fi
  cat <<EOF

  ${BOLD}Next:${RESET}
    • ${BOLD}exec zsh${RESET} (or open a new terminal) to load everything
    • Machine-specific stuff goes in ${BOLD}~/.zshrc.local${RESET} and ${BOLD}~/.gitconfig.local${RESET} (untracked)
    • Full log: ${DIM}${LOG/#$HOME/$TILDE}${RESET}

EOF
}

main
