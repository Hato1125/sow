# sow

A zero-dependency, self-contained dotfile bootstrapper written in Bash. Deploy packages and symlink dotfiles with a single command.

sow is a single shell script with no external dependencies beyond Bash itself. Add it to your dotfiles repository as a Git submodule and you can bootstrap any machine with just `git clone` and `git submodule update` -- no package manager, no installer, no runtime needed.

## Usage

```
sow [COMMAND] [OPTION]...
```

### Commands

| Command  | Description                          |
| -------- | ------------------------------------ |
| `deploy` | Deploy packages and/or dotfiles      |
| `help`   | Display usage information            |

### Options

| Option | Description                                  |
| ------ | -------------------------------------------- |
| `-p`   | Target packages only                         |
| `-d`   | Target dotfiles only                         |
| `-n`   | Dry run; print actions without executing them |

By default (no `-p` or `-d`), both packages and dotfiles are deployed.

### Examples

```bash
# Deploy everything
bash sow.sh deploy

# Deploy only dotfiles
bash sow.sh deploy -d

# Preview what would happen without making changes
bash sow.sh deploy -n
```

## Configuration

### pkg.conf

Defines the package manager command and the list of packages to install. This file is sourced as Bash.

```bash
install=(paru -S --needed --noconfirm)

pkgs=(
  git
  neovim
  zed
)
```

- `install` -- array containing the install command and its flags.
- `pkgs` -- array of package names to install.

### dot.conf

Defines a mapping from local paths to their deployment destinations. This file is sourced as Bash.

```bash
declare -A dots=(
  [./test]="$HOME/.config/test"
  [./test2]="$HOME/.config/test2"
)
```

- Directory sources are recursively symlinked into the destination using `cp -rs`. Existing symlinks in the destination are cleaned before re-linking.
- Single-file sources are symlinked with `cp -sf`. If the destination already exists as a regular file (not a symlink), it is left untouched.

## Getting Started

The recommended way to use sow is as a Git submodule inside your dotfiles repository. This keeps your dotfiles self-contained -- cloning the repo brings everything you need, with no additional installation steps.

```bash
# In your dotfiles repo
git submodule add https://github.com/Hato1125/sow.git sow
```

On a fresh machine, just clone and go:

```bash
git clone --recurse-submodules https://github.com/you/dotfiles.git
cd dotfiles
bash sow/sow.sh deploy
```

Or if you already cloned without `--recurse-submodules`:

```bash
git clone https://github.com/you/dotfiles.git
cd dotfiles
git submodule update --init
bash sow/sow.sh deploy
```

That's it. Git and Bash are the only prerequisites.

## Real-World Example

A practical repository layout based on [Hato1125/dotfiles](https://github.com/Hato1125/dotfiles):

```
dotfiles/
├── sow/             # git submodule
├── pkg.conf
├── dot.conf
└── dots/
    ├── ghostty/
    │   └── config
    ├── gtk-3.0/
    │   ├── bookmarks
    │   ├── gtk.css
    │   └── settings.ini
    ├── gtk-4.0/
    │   ├── gtk.css
    │   └── settings.ini
    ├── hypr/
    │   └── hyprland.conf
    ├── nvim/
    │   ├── init.lua
    │   └── lua/
    ├── starship/
    │   └── starship.toml
    ├── zed/
    │   ├── keymap.json
    │   ├── settings.json
    │   └── themes/
    ├── .zprofile
    └── .zshrc
```

**pkg.conf**

```bash
install=(paru -S --needed --noconfirm)

pkgs=(
  ninja
  meson
  cmake
  gcc
  clang
  zed
  zsh
  neovim
  ghostty
  starship
  docker-desktop
  zen-browser
  vesktop
  uwsm
  # ...
)
```

**dot.conf**

```bash
declare -A dots=(
  # Directories -> ~/.config/<app>
  [./dots/ghostty]="$HOME/.config/ghostty"
  [./dots/gtk-3.0]="$HOME/.config/gtk-3.0"
  [./dots/gtk-4.0]="$HOME/.config/gtk-4.0"
  [./dots/hypr]="$HOME/.config/hypr"
  [./dots/nvim]="$HOME/.config/nvim"
  [./dots/starship]="$HOME/.config/starship"
  [./dots/zed]="$HOME/.config/zed"

  # Single files -> ~/
  [./dots/.zprofile]="$HOME/.zprofile"
  [./dots/.zshrc]="$HOME/.zshrc"
)
```

Deploying on a new machine:

```bash
git clone --recurse-submodules https://github.com/Hato1125/dotfiles.git
cd dotfiles
bash sow/sow.sh deploy
```

## License

[BSD 2-Clause](LICENSE)
