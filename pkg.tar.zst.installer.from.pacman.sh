#!/bin/bash

function _install_pkg.tar.zst_from_pacman {
  local package_name=$1
  local run=$5
  local is_package_dependency=$6

  print_installing $package_name "pacman" $is_package_dependency
  yes | sudo pacman -S $1 1>/dev/null 2>&1
  echo $(pc "  ✓" $green)
}
