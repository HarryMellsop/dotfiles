# for every dotfile in the dotfiles directory, create a symlink in the home directory

import glob
import pathlib
import questionary

home = pathlib.Path.home()
parent_dir = pathlib.Path(__file__).parent.absolute()

def main():
    for dotfile in glob.glob(f"{parent_dir}/.*"):
        # create symlink in home directory
        home_dotfile = home / pathlib.Path(dotfile).name
        print(home_dotfile)

        if home_dotfile.exists():
            should_overwrite = questionary.confirm(f"Overwrite {home_dotfile}?").ask()
            if should_overwrite:
                home_dotfile.unlink()
            else:
                continue

        # do not symlink git files
        if home_dotfile.name in [".git", ".gitignore"]:
            continue

        home_dotfile.symlink_to(dotfile)
        print(f"Created symlink {home_dotfile} -> {dotfile}")

    # create nvim config directory
    nvim_config_dir = home / ".config" / "nvim"
    nvim_config_dir.mkdir(parents=True, exist_ok=True)

    # create symlink to nvim config
    nvim_config = nvim_config_dir / "init.vim"
    nvim_config.symlink_to(home / ".vimrc")
