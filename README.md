# dotfiles

My shell, editor, git, tmux and atuin config, plus an installer that sets up a new Mac (or Linux box) from scratch.

## New machine

```sh
bash -c "$(curl -fsSL https://raw.githubusercontent.com/HarryMellsop/dotfiles/master/install.sh)"
```

It asks two questions up front (CLI tools? GUI apps?) and then runs on its own:

1. Xcode Command Line Tools
2. Clones this repo to `~/.dotfiles`
3. Homebrew and the [`Brewfile`](Brewfile): core tools always, plus CLI tools and apps if you said yes
4. oh-my-zsh
5. Symlinks everything in [`home/`](home) into `~`. Anything it replaces is moved to `~/.dotfiles-backup/<timestamp>/`
6. Copies the configs in [`seed/`](seed) once (for apps that rewrite their own settings)
7. Plugins: tmux (tpm), neovim (vim-plug + YouCompleteMe), bash-preexec for atuin
8. Optional logins: `gh auth login`, `atuin login`

Re-running it is safe. Steps that are already done get skipped.

```sh
./install.sh --dry-run      # show the plan, change nothing
./install.sh --links-only   # just relink after a git pull
./install.sh --yes          # no questions, skip logins
./install.sh --no-brew      # skip Homebrew entirely
```

## Layout

| Path | What happens to it |
| --- | --- |
| `home/` | Symlinked file by file into `~` (e.g. `home/.config/atuin/config.toml` → `~/.config/atuin/config.toml`) |
| `seed/` | Copied once if missing, never overwritten (Claude Code and Zed settings) |
| `Brewfile` | `brew bundle`. The `DOTFILES_BREW_CLI` / `DOTFILES_BREW_APPS` env vars switch on the optional sections |

To track a new dotfile, move it into `home/` at the same relative path and run `./install.sh --links-only`.

## Machine-local and secret stuff

None of this is tracked (the repo is public):

- `~/.zshrc.local` is sourced at the end of `.zshrc`. Put API keys, work-only aliases, etc. here
- `~/.gitconfig.local` is included by `.gitconfig`. Use it for a work email, signing keys, etc.
- atuin's sync key and session stay in `~/.local/share/atuin/`. On a new machine, run `atuin key` on the old one, then `atuin login` and `atuin sync`
