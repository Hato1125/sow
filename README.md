# sow

A zero-dependency, self-contained dotfile bootstrapper written in Bash. Deploy packages and symlink dotfiles with a single command.

sow is a single shell script with no external dependencies beyond Bash itself. Add it to your dotfiles repository as a Git submodule and you can bootstrap any machine with just `git clone` and `git submodule update` -- no package manager, no installer, no runtime needed.

## Usage

```
sow [COMMAND] [OPTION]...
```

### Commands

|Command |Description|
|-|-|
|`deploy`|Deploy packages and/or dotfiles|
|`help`|Display usage information|

### Options

|Option|Description|
|-|-|
|`-p`|Target packages only|
|`-d`|Target dotfiles only|
|`-n`|Dry run; print actions without executing them|

By default (no `-p` or `-d`), both packages and dotfiles are deployed.

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

Defines an indexed array of alternating source and destination paths. This file is sourced as Bash.

```bash
dots=(
  ./test  "$HOME/.config/test"
  ./test2 "$HOME/.config/test2"
)
```

Each source must be followed by its destination. A source may appear more than once, but duplicate destinations are rejected before deployment.

- Directory sources are recursively symlinked into the destination using `cp -rs`. Existing symlinks in the destination are cleaned before re-linking.
- Single-file sources are symlinked with `cp -sf`. If the destination already exists as a regular file (not a symlink), it is left untouched.

## License

[BSD 2-Clause](LICENSE)
