#!/bin/bash

function _install_deb_from_apt {
  local package_name=$1
  local repository=$2
  local run=$5
  local is_package_dependency=$6
  local is_last_item=$8

  if [ -n "$repository" ]; then
    local is_ppa_added
    is_ppa_added="$(apt-cache policy | grep -q "$repository")"

    if [ -z "$is_ppa_added" ]; then
      _print_adding_repository "$repository"
      sudo add-apt-repository ppa:"$repository" -y 1>/dev/null
      sudo apt-get update -y 1>/dev/null
      _print_success "$repository" "added" "to sources list" "$is_package_dependency"
    fi
  fi

  if [ -n "$run" ]; then
    _run_command "$run"
  fi

  _print_installing "$package_name" "apt" "$is_package_dependency"
  local debconf_warning="debconf: delaying package configuration, since apt-utils is not installed"
  local templates_warning="Extracting templates from packages: 100%"

  local is_package_installed
  local install_command
  local error_log_file

  error_log_file="$HOME/dotfiles/script/logs/$(date +%F)_error_installing_$package_name.log"
  install_command="DEBIAN_FRONTEND=noninteractive apt-get install -y ${package_name}"

  _exec_with_sudo "$install_command" "$error_log_file" | grep -v "$debconf_warning" | grep -v "$templates_warning"

  is_package_installed="$(_is_deb_installed "$package_name")"

  if [ -n "$is_package_installed" ]; then
    _is_package_installed "$package_name" "deb" "" "$is_package_dependency" "$is_last_item" true
  else
    _print_error "$package_name" "cannot be installed" "$is_package_dependency" "$(cat "$error_log_file")" 
  fi
}
