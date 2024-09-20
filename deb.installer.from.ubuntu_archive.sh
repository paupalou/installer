#!/bin/bash

function _install_deb_from_ubuntu_archive {
  local package_name=$1
  local repository=$2
  local version=$3
  local arch=$7

  print_installing "$package_name" "ubuntu"

  local package_file=${package_name}_${version}_${arch}.deb
  wget "http://es.archive.ubuntu.com/ubuntu/pool/universe/$repository/$package_file" &>/dev/null

  sudo dpkg -i "$package_file" 1>/dev/null
  rm "$package_file"
  echo $(pc "  ✓" $green)
}
