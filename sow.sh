#!/bin/bash

readonly PKG_CONFIG_PATH='./pkg.conf'
readonly DOT_CONFIG_PATH='./dot.conf'

target_pkg=false
target_dot=false
dryrun=false

help() {
  echo 'Usage: sow [COMMAND] [OPTION]...'
  echo 'Self-contained dotfile bootstrapper.'
  echo ''
  echo 'Commands'
  echo '  deploy'
  echo '    deployment packages and dotfiles'
  echo '  help'
  echo '    display this help and exit'
  echo ''
  echo 'Options'
  echo '  -p'
  echo '    target packages only'
  echo '  -d'
  echo '    target dotfiles only'
  echo '  -n'
  echo '    dry run; print actions without executing them'
}

install_pkgs() (
  source "$PKG_CONFIG_PATH"

  if [[ ! -v install ]]; then
    echo "${PKG_CONFIG_PATH}: no install command defined" >&2
    exit 1
  fi

  if [[ ! -v pkgs ]]; then
    echo "${PKG_CONFIG_PATH}: no pkgs defined" >&2
    exit 1
  fi

  [[ ${#pkgs[@]} -eq 0 ]] && exit 0

  if $dryrun; then
    echo "${install[@]}" "${pkgs[@]}"
  else
    exec "${install[@]}" "${pkgs[@]}"
  fi
)

install_dots() (
  source "$DOT_CONFIG_PATH" || exit 1

  if ! declare -p dots &>/dev/null; then
    echo "${DOT_CONFIG_PATH}: no dots defined" >&2
    exit 1
  fi

  if [[ $(declare -p dots) != "declare -a "* ]]; then
    echo "${DOT_CONFIG_PATH}: dots must be an indexed array" >&2
    exit 1
  fi

  if (( ${#dots[@]} % 2 != 0 )); then
    echo "${DOT_CONFIG_PATH}: dots must contain source-destination pairs" >&2
    exit 1
  fi

  [[ ${#dots[@]} -eq 0 ]] && exit 0

  declare -A destinations=()

  for ((i = 0; i < ${#dots[@]}; i += 2)); do
    src="${dots[i]}"
    dst="${dots[i + 1]}"

    if [[ -z "$src" || -z "$dst" ]]; then
      echo "${DOT_CONFIG_PATH}: dotfile paths must not be empty" >&2
      exit 1
    fi

    if [[ ${destinations["$dst"]+registered} ]]; then
      echo "${DOT_CONFIG_PATH}: duplicate destination: $dst" >&2
      exit 1
    fi

    destinations["$dst"]="$src"
  done

  for ((i = 0; i < ${#dots[@]}; i += 2)); do
    src="$(realpath "${dots[i]}")"
    dst="${dots[i + 1]}"

    if [[ -d "$src" ]]; then
      if $dryrun; then
        [[ -d "$dst" ]] && echo "find $dst -type l -delete"
        echo "mkdir -p $dst"
        echo "cp -rs $src/. $dst"
      else
        [[ -d "$dst" ]] && find "$dst" -type l -delete
        mkdir -p "$dst"
        cp -rs "$src/." "$dst"
      fi
    else
      if [[ -e "$dst" && ! -L "$dst" ]]; then
        continue
      fi

      if $dryrun; then
        echo "mkdir -p $(dirname "$dst")"
        echo "cp -sf $src $dst"
      else
        mkdir -p "$(dirname "$dst")"
        cp -sf "$src" "$dst"
      fi
    fi
  done
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
    echo "sow: unknown command: $cmd" >&2
    help >&2
    exit 1
    ;;
esac
