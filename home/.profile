# ~/.profile — for sh/bash login shells. Managed by ~/dotfiles.
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
[ -f "$HOME/.atuin/bin/env" ] && . "$HOME/.atuin/bin/env"
true
