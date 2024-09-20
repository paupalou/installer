#!/bin/bash

source ./script/yaml_parser.sh
source ./script/print_utils.sh

function _install_item {
  local item=$1
  local is_subitem=$2
  local is_last_item=$3
  local should_install=true

  local name=$(_get_value $item "name" ${!item})
  local from=$(_get_value $item "from" $package_manager)
  local type=$(_get_value $item "type" $package_type)
  local arch=$(_get_value $item "arch" $package_arch)
  local version_cmd=$(_get_value $item "version_cmd")
  local repository=$(_get_value $item "repository")
  local release=$(_get_value $item "release")
  local path=$(_get_value $item "path")
  local run=$(_get_value $item "run")

  if _is_package_installed "$name" "$type" "$version_cmd" "$is_subitem" "$is_last_item"; then
    should_install=false
  fi

  local depends=${item}_depends_
  if [ -n "${!depends}" ]; then
    local index=1
    local dependencys=${!depends}
    local num_deps=$(echo "${dependencys}" | wc -w)
    for dependency in ${!depends}; do
      index=$((index + 1))
      local is_last_item
      if [ "$index" -gt "$num_deps" ]; then
        is_last_item=true
      fi
      _install_item "$dependency" true "$is_last_item"
    done
  fi

  if [ "$should_install" = true ]; then
    if ! _is_installer_loaded $type $from; then
      source ./script/$type.installer.from.$from.sh
    fi

    _run_hooks "pre" $item

    _install_${type}_from_${from} "$name" "$repository" "$release" "$path" "$run" "$is_subitem" "$arch" "$is_last_item"

    _run_hooks "post" $item
  fi
}

function _install_category_items {
  local category=$1
  local items=${category}_
  if [ -z "${!items}" ]; then
    return 0
  fi

  _start $category

  for item in ${!items}; do
    _install_item $item
  done

  _end
}

function _is_package_installed {
  local package=$1
  local type=$2
  local version_cmd=$3
  local is_subitem=$4
  local is_last_item=$5
  local post_install=$6
  local version

  if [ -z "$version_cmd" ]; then
    if ! _is_checker_loaded $type; then
      local checker=./script/$type.checker.sh
      if [ -f "$checker" ]; then
        source $checker
        version=$(_is_${type}_installed $package)
      else
        version="$($package --version 2>/dev/null | head -1 | grep -o -e '[0-9]\+\(\.[0-9]\+\)*' | head -1)"
      fi
    else
      version=$(_is_${type}_installed $package)
    fi
  else
    version="$(eval $version_cmd 2>/dev/null | head -1 | grep -o -e '[0-9]\+\(\.[0-9]\+\)*' | head -1)"
  fi

  if [ -z "$version" ]; then
    # _print_pkg_error $package $is_subitem
    return 1
  fi

  _print_pkg_success "$package" "$version" "$is_subitem" "$is_last_item" "$post_install"
  return 0
}

function _install_source_from_github {
  local name=$1
  local repository=$2
  local source_path=$4
  local run=$5

  print_installing $name "github"
  git clone --depth 1 https://github.com/${repository}.git ${source_path} &>/dev/null
  cd $source_path
  _run_command "$run"
  cd -

  echo $(pc "  ✓" $green)
}

function _install_binary_from_curl {
  local name=$1
  local run=$5

  print_installing $name "curl"

  _run_command "$run"

  echo $(pc "  ✓" $green)
}

function _install {
  local install_file
  install_file=$(_grab_file "install.yml")

  eval "$(parse_yaml "$install_file")"
  _check_sudo
  _is_sudo_cred_cached

  _set_localtime
  local category_group

  if [ -z "$1" ]; then
    category_group=$__
  else
    category_group=$1
  fi

  for category in $category_group; do
    _install_category_items "$category"
  done
}
