# ~/.zprofile — login-shell PATH setup. Managed by ~/dotfiles.

# Homebrew — each shellenv prepends, so the last one found wins (Apple Silicon over Intel).
for brew_bin in /home/linuxbrew/.linuxbrew/bin/brew /usr/local/bin/brew /opt/homebrew/bin/brew; do
  [ -x "$brew_bin" ] && eval "$("$brew_bin" shellenv)"
done
unset brew_bin

# Latest Homebrew Python as plain `python`/`python3`/`pip`. python@3 tracks brew's
# current default (3.13 today), so this moves forward on its own.
if [ -n "${HOMEBREW_PREFIX:-}" ] && [ -d "$HOMEBREW_PREFIX/opt/python@3/libexec/bin" ]; then
  export PATH="$HOMEBREW_PREFIX/opt/python@3/libexec/bin:$PATH"
fi

# Obsidian CLI
[ -d /Applications/Obsidian.app ] && export PATH="$PATH:/Applications/Obsidian.app/Contents/MacOS"
true
