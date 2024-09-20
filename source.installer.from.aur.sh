#!/bin/bash

function _install_source_from_aur {
  local package_name=$1
  local source_path=$4
  local is_package_dependency=$6

  print_installing $package_name "aur" $is_package_dependency

  git clone https://aur.archlinux.org/${package_name}.git ${source_path} &>/dev/null
  cd $source_path &>/dev/null
  yes | makepkg -si &>/dev/null
  cd - &>/dev/null

  echo $(pc "  ✓" $green)
}
