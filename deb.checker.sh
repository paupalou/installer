#!/bin/bash

function _is_deb_installed {
  local item=$1
  local is_installed
  is_installed="$(dpkg -s "$item" 2>/dev/null | grep '^Status: install ok installed$')"

  if [ -n "$is_installed" ]; then
    dpkg -s "$item" 2>/dev/null | grep '^Version' | cut -d ' ' -f 2 | cut -d : -f 2 | cut -d - -f 1 | cut -d + -f 1
  fi
}
