# ~/.bashrc — managed by ~/dotfiles. atuin needs bash-preexec (install.sh fetches it).
[ -f "$HOME/.atuin/bin/env" ] && . "$HOME/.atuin/bin/env"
[[ -f ~/.bash-preexec.sh ]] && source ~/.bash-preexec.sh
command -v atuin >/dev/null && eval "$(atuin init bash)"
true
