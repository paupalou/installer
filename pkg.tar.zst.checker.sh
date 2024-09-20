#!/bin/bash

function _is_pkg.tar.zst_installed {
  local item=$1
  local is_installed="$(pacman --query $item 2>/dev/null)"

  if [ -n "$is_installed" ]; then
    echo "$(echo $is_installed | grep -o -e '[0-9]\+\(\.[0-9]\+\)*' | head -n 1)"
  fi
}
