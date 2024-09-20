#!/bin/bash

function _install_deb_from_github {
  local package_name=$1
  local repository=$2
  local release=$3
  local arch=$7

  _print_installing "$repository" "github"

  local package_file=${package_name}_${release}_${arch}.deb

  # if package has not specified release version grab latest release
  if [ -z "$release" ]; then
    local latest_release
    latest_release=$(curl --silent "https://api.github.com/repos/$repository/releases/latest" |
      grep '"tag_name":' |
      sed -E 's/.*"([^"]+)".*/\1/')

    package_file=${package_name}_${latest_release}_${arch}.deb
    if [ "${latest_release:0:1}" = v ]; then
      # in case we curl version like v1.2.3 remove the v
      package_file=${package_name}_${latest_release:1}_${arch}.deb
    fi
  fi

  wget "https://github.com/$repository/releases/download/$release/$package_file" &>/dev/null

  sudo dpkg -i "$package_file" 1>/dev/null
  rm "$package_file"

  _success 2
}
