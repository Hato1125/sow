#!/bin/bash

readonly PKG_CONFIG_PATH='./pkg.conf'
readonly DOT_CONFIG_PATH='./dot.conf'

target_pkg=false
target_dot=false
dryrun=false

help() {
  cat <<'EOF'
Usage: sow [COMMAND] [OPTION]...
Self-contained dotfile bootstrapper.

Commands
  deploy
    deployment packages and dotfiles
  help
    display this help and exit

Options
  -p
    target packages only
  -d
    target dotfiles only
  -n
    dry run; print actions without executing them
EOF
}

install_pkgs() (
  source "$PKG_CONFIG_PATH"

  if [[ ! -v install ]]; then
    printf '%s\n' "${PKG_CONFIG_PATH}: no install command defined" >&2
    exit 1
  fi

  if [[ ! -v pkgs ]]; then
    printf '%s\n' "${PKG_CONFIG_PATH}: no pkgs defined" >&2
    exit 1
  fi

  [[ ${#pkgs[@]} -eq 0 ]] && exit 0

  if $dryrun; then
    printf '%q ' "${install[@]}" "${pkgs[@]}"
    printf '\n'
  else
    exec "${install[@]}" "${pkgs[@]}"
  fi
)

install_dots() (
  source "$DOT_CONFIG_PATH" || exit 1

  if ! declare -p links &>/dev/null && ! declare -p copies &>/dev/null; then
    printf '%s\n' "${DOT_CONFIG_PATH}: no links or copies defined" >&2
    exit 1
  fi

  declare -A destinations=()

  validate_paths() {
    local name="$1"
    local -n paths="$name"
    local src dst resolved_src

    if [[ $(declare -p "$name") != "declare -a "* ]]; then
      printf '%s\n' "${DOT_CONFIG_PATH}: $name must be an indexed array" >&2
      return 1
    fi

    if (( ${#paths[@]} % 2 != 0 )); then
      printf '%s\n' \
        "${DOT_CONFIG_PATH}: $name must contain source-destination pairs" >&2
      return 1
    fi

    for ((i = 0; i < ${#paths[@]}; i += 2)); do
      src="${paths[i]}"
      dst="${paths[i + 1]}"

      if [[ -z $src || -z $dst ]]; then
        printf '%s\n' "${DOT_CONFIG_PATH}: paths must not be empty" >&2
        return 1
      fi

      if [[ $name == copies ]]; then
        resolved_src="$(realpath "$src")"

        if [[ ! -f $resolved_src ]]; then
          printf '%s\n' \
            "${DOT_CONFIG_PATH}: copy source must be a regular file: $src" >&2
          return 1
        fi

        if [[ -d $dst && ! -L $dst ]]; then
          printf '%s\n' \
            "${DOT_CONFIG_PATH}: copy destination is a directory: $dst" >&2
          return 1
        fi
      fi

      if [[ ${destinations["$dst"]+registered} ]]; then
        printf '%s\n' "${DOT_CONFIG_PATH}: duplicate destination: $dst" >&2
        return 1
      fi

      destinations["$dst"]="$src"
    done
  }

  if declare -p links &>/dev/null; then
    validate_paths links || exit 1
  fi

  if declare -p copies &>/dev/null; then
    validate_paths copies || exit 1
  fi

  link_path() {
    local src="$1" dst="$2" child

    if [[ -L $dst ]]; then
      if [[ $(readlink "$dst") == "$src" ]]; then
        return 0
      fi
      printf 'sow: destination conflict: %s\n' "$dst" >&2
      return 1
    fi

    if [[ -d $src && ! -L $src ]]; then
      if [[ -e $dst && ! -d $dst ]]; then
        printf 'sow: destination conflict: %s\n' "$dst" >&2
        return 1
      fi

      if $dryrun; then
        printf 'mkdir -p -- %q\n' "$dst"
      else
        mkdir -p -- "$dst" || return 1
      fi

      for child in "$src"/*; do
        link_path "$child" "$dst/${child##*/}" || return 1
      done
    elif [[ -e $dst ]]; then
      printf 'sow: destination conflict: %s\n' "$dst" >&2
      return 1
    elif $dryrun; then
      printf 'mkdir -p -- %q\n' "$(dirname "$dst")"
      printf 'ln -s -- %q %q\n' "$src" "$dst"
    else
      mkdir -p -- "$(dirname "$dst")" || return 1
      ln -s -- "$src" "$dst" || return 1
    fi
  }

  if declare -p links &>/dev/null; then
    shopt -s dotglob nullglob
    for ((i = 0; i < ${#links[@]}; i += 2)); do
      src="$(realpath -e -- "${links[i]}")" || exit 1
      dst="${links[i + 1]}"
      link_path "$src" "$dst" || exit 1
    done
  fi

  if declare -p copies &>/dev/null; then
    for ((i = 0; i < ${#copies[@]}; i += 2)); do
      src="$(realpath "${copies[i]}")"
      dst="${copies[i + 1]}"

      if $dryrun; then
        [[ -L $dst ]] && printf 'rm %q\n' "$dst"
        printf 'mkdir -p %q\n' "$(dirname "$dst")"
        printf 'cp -f %q %q\n' "$src" "$dst"
      else
        [[ -L $dst ]] && rm "$dst"
        mkdir -p "$(dirname "$dst")"
        cp -f "$src" "$dst"
      fi
    done
  fi
)

cmd="$1"
shift

while getopts "pdn" opt; do
  case $opt in
    p) target_pkg=true ;;
    d) target_dot=true ;;
    n) dryrun=true ;;
  esac
done

if ! $target_pkg && ! $target_dot; then
  target_pkg=true
  target_dot=true
fi

case "$cmd" in
  deploy)
    if $target_pkg; then
      install_pkgs
    fi

    if $target_dot; then
      install_dots
    fi
    ;;
  help|'') help ;;
  *)
    printf '%s\n' "sow: unknown command: $cmd" >&2
    help >&2
    exit 1
    ;;
esac
