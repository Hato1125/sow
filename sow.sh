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
  source "$DOT_CONFIG_PATH"

  if ! declare -p dots &>/dev/null; then
    echo "${DOT_CONFIG_PATH}: no dots defined" >&2
    exit 1
  fi

  [[ ${#dots[@]} -eq 0 ]] && exit 0

  for key in "${!dots[@]}"; do
    src="$(realpath "$key")"
    dst="${dots[$key]}"

    if $dryrun; then
      echo "mkdir -p $(dirname "$dst")"
      if [[ -d "$src" ]]; then
        echo "cp -rs $src/. $dst"
      else
        echo "cp -sf $src $dst"
      fi
    else
      mkdir -p "$(dirname "$dst")"
      if [[ -d "$src" ]]; then
        cp -rs "$src/." "$dst"
      else
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
