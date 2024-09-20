#!/bin/bash

## Foreground
# default color
def='\e[39m'

# 8 Colors
black='\e[30m'
red='\e[31m'
green='\e[32m'
yellow='\e[33m'
blue='\e[34m'
magenta='\e[35m'
cyan='\e[36m'
lgray='\e[37m'

# 16 Colors
dgray='\e[90m'
lred='\e[91m'
lgreen='\e[92m'
lyellow='\e[93m'
lblue='\e[94m'
lmagenta='\e[95m'
lcyan='\e[96m'
white='\e[97m'

## Background
# 8 Colors
# default bg color
defbg='\e[49m'
blackbg='\e[40m'
redbg='\e[41m'
greenbg='\e[42m'
yellowbg='\e[43m'
bluebg='\e[44m'
magentabg='\e[45m'
cyanbg='\e[46m'
lgraybg='\e[47m'

# 16 Colors
dgraybg='\e[100m'
lredbg='\e[101m'
lgreenbg='\e[102m'
lyellowbg='\e[103m'
lbluebg='\e[104m'
lmagentabg='\e[105m'
lcyanbg='\e[106m'
whitebg='\e[107m'

# used to reset attributes
normal='\e[0m'
bold='\e[1m'
uline='\e[4m'
inverted='\e[7m'

print_deps=true

BOX_SIZE=72

function _repeat(){
  local start=1
  local end=${1:-80}
  local default=.
  local str="${2:-$default}"
  local range
  range="$(seq "$start" "$end")"
  for i in $range ; do echo -n "${str}"; done
}

function _add_whitespaces() {
  _repeat "$1" " "
}

function _save_cursor_position {
  printf "\e[s"
}

function _restore_cursor_position {
  printf "\e[u"
}

function _add_boxline() {
  _newline
  # tput cup "$(_current_row)" 0

  pc "│" "$lblue"
  _save_cursor_position
  local spaces=$(($(_box_max_width) - 2))

  _add_whitespaces $spaces
  pc "│" "$lblue"
  _restore_cursor_position
  # _move_cursor_column_backward $((spaces + 1))
}

# function _col {
#   local COL
#   local ROW
#   IFS=';' read -sdR -p $'\E[6n' ROW COL
#   echo "${COL}"
# }


# function _current_position {
#   exec < /dev/tty
#   oldstty=$(stty -g)

#   stty raw -echo min 0
#   echo -en "\033[6n" > /dev/tty

#   IFS=';' read -r -d R -a pos
#   stty "$oldstty"
# }

function _current_row {
  _current_position
  local row=$((${pos[0]:2} - 1))
  echo $row;
}

function _current_col {
  _current_position
  local col=$((pos[1] - 1))
  echo $col;
}


function _move_cursor_row_backward {
  local rows=${1:-0}
  tput cup "$(($(_current_row) - $rows))" "$(_current_col)"
}

function _move_cursor_row_forward {
  local rows=${1:-0}
  tput cup "$(($(_current_row) + $rows))" "$(_current_col)"
}

function _move_cursor_column_backward {
  local cols=${1:-0}
  # echo "current row $(_current_row)"
  # echo "cols $cols"
  tput cup "$(_current_row)" "$(($(_current_col) - $cols))"
}

function _move_cursor_column_forward {
  local cols=${1:-0}
  tput cup "$(_current_row)" "$(($(_current_col) + $cols))"
}

################################
# Print a colored message      #
# Arguments:                   #
#  $1 message                  #
#  $2 color and/or textstyle   #
################################
function pc() {
  local message=$1
  if [ -z "$message" ]; then
    return
  fi

  # Defaults to normal, if not specified.
  local color=${2:-$normal}

  printf "%b%s" "$color" "$message"

  # Reset to normal.
  printf "%b" "$normal"

  return
}

function _cr {
  printf "\r\n"
}

function _newline {
  printf "\n"
}

function _child {
  printf "\r%s" "$1"
}

function _success {
  local padding=$1
  local color=${2:-$green}

  printf "%b%${padding}s" "$color" "✓"
}

function _error {
  local padding=$1
  local color=${2:-$red}

  printf "%b%${padding}s" "$color" "✗"
}

function _right_border() {
  local column=$(($(_box_max_width) - 1))
  echo -e "\033[${column}G $(pc "│" "$lblue")"
}

function _subchild {
  local action=$1
  local item=$2
  local item_extra=$3
  local is_child=$4

  if [ -n "$is_child" ] && [ $print_deps == false ]; then
    return
  fi

  _cr
  pc "│" "$lblue"
  pc "   "

  if [ -n "$is_child" ]; then
    pc "├── " "$lgray"
  fi

  pc "∷ " "$lgray"
  pc "$action" "$uline$lgray"
  pc " $item"
  pc " $item_extra" "$lgray"
  _right_border
}

function _box_max_width {
  if [[ "$(tput cols)" -lt BOX_SIZE ]]; then
    echo $(tput cols)
  else
    echo $BOX_SIZE
  fi
}

function _start {
  local item=$1
  local line_start="┌─────────"

  local line_end="───────────────────────────────────────────────────────────┐"
  line_end=${line_end:BOX_SIZE-$(_box_max_width)}

  pc "$line_start $item" "$bold$lblue"
  pc " ${line_end:${#item}}" "$bold$lblue"
}

function _end {
  local line="└──────────────────────────────────────────────────────────────────────┘"
  line=${line:BOX_SIZE-$(_box_max_width)}

  _newline
  pc "$line" "$bold$lblue"
  _cr
}

function _print_pkg_success {
  local package=$1
  local package_version=$2
  local is_package_dependency=$3
  local is_last_item=$4
  local post_install=$5

  # fill with 40 spaces
  local version_label="                                         version "
  local chars_to_remove
  chars_to_remove=$(("$BOX_SIZE"-"$(_box_max_width)"))

  if (( chars_to_remove > 22 )); then
    chars_to_remove=$(("$chars_to_remove"-12))
    version_label="                                         v"
  fi

  if [ -n "$is_package_dependency" ] && [ $print_deps == false ]; then
    return
  fi

  local package_color=$normal
  version_label=${version_label:$chars_to_remove}

  if [ -n "$post_install" ]; then
    _move_cursor_row_backward 1
  fi

  _add_boxline

  if [ -n "$is_package_dependency" ]; then
    local character="├"
    if [ -n "$is_last_item" ]; then
      character="└"
    fi

    pc "   $character" "$lgray"
    # remove 4 spaces added in last print from version_label
    version_label=${version_label:4}
    package_color=$lgray
  fi

  _success "4"
  pc " $package" "$package_color"
  if (( $(_box_max_width) > 30 )); then
    pc "${version_label:${#package}}" "$dgray"
    local offset
    offset=$(("$(_box_max_width)" - "$(_col)" - 1))
    pc "${package_version:0:$offset}" "$cyan"
  fi
  # _right_border
}

function _print_pkg_error {
  local package=$1
  local is_package_dependency=$2
  local is_last_item=$3

  if [ -n "$is_package_dependency" ] && [ $print_deps == false ]; then
    return
  fi

  local not_installed_label="not installed"
  local package_color=$normal

  _cr
  pc "│" "$lblue"

  if [ -n "$is_package_dependency" ]; then
    local character="├"
    if [ -n "$is_last_item" ]; then
      character="└"
    fi

    pc "   $character" "$lgray"
    package_color=$lgray
  fi

  _error 4
  pc " $package" "$package_color"
  pc " $not_installed_label" "$lgray"
  _right_border
}

function _print_installing {
  local item=$1
  local item_from=$2
  local is_package_dependency=$3

  if [ -n "$is_package_dependency" ] && [ $print_deps == false ]; then
    return
  fi

  _add_boxline
  _add_whitespaces 1

  if [ -n "$is_package_dependency" ]; then
    _add_whitespaces 2
    pc "├ " "$lgray"
  fi

  pc "∷ " "$lgray"
  pc "installing" "$uline$lgray"

  _add_whitespaces 1
  pc "$item"

  _add_whitespaces 1
  pc "from $item_from" "$lgray"
}

function _print_success {
  local item=$1
  local action_done=$2
  local details=$3
  local is_package_dependency=$4

  if [ -n "$is_package_dependency" ] && [ $print_deps == false ]; then
    return
  fi

  _success
  pc " $item"
  pc " $action_done" "$green"
  pc " $details              " "$lgray"
}

function _print_error {
  local item=$1
  local action_done=$2
  local is_package_dependency=$3
  local details=$4

  if [ -n "$is_package_dependency" ] && [ $print_deps == false ]; then
    return
  fi

  _move_cursor_row_backward 1
  _add_boxline

  if [ -n "$is_package_dependency" ]; then
    local character="├"
    if [ -n "$is_last_item" ] && [ -z "$details" ]; then
      character="└"
    fi

    _add_whitespaces 3
    pc "$character" "$lgray"
    package_color=$lgray
  fi

  _add_whitespaces 1
  _error

  pc " $item"
  local maxLength
  maxLength=$(("$(_box_max_width)"-"$(_col)" - 1))

  printf "%b%-${maxLength}s" "$red" " ${action_done:0:$maxLength}"

  _add_boxline

  maxLength=$(("$(_box_max_width)"-"$(_col)" - 1))
  _add_whitespaces 3

  if [ -n "$is_package_dependency" ]; then
    pc "┆" "$lgray"
    _add_whitespaces 1
  fi

  pc "${details:0:$maxLength}" "$lgray"
}

function _print_adding_repository {
  _subchild "adding" $1 "repository"
}

function print_help_option {
  printf "$(printf "%-40s\n" "$bold $1")$normal $2\n"
}

function user {
  local character=└
  if [ -z ${is_last_item} ]; then
    local character=├
  fi
  _child "$(pc "│ $character──" $lblue) [$(pc ' ? ' $yellow)] $1\n"
}

function user_option {
  _child "$(pc "│" $lblue) $(pc "│" $lblue)         $1\n"
  # $(pc │ $lblue)         ├─› [${bold}s${normal}]kip ──────── [${bold}S${normal}]kip all
}

function warn {
  local character=└
  if [ -z ${is_last_item} ]; then
    local character=├
  fi
  _child "$(pc "│ $character──" $lblue) [$(pc ' ! ' $lred)] $1\n"
}

function success {
  local character=└
  if [ -z ${is_last_item} ]; then
    local character=├
  fi
  _child "$(pc "│ $character──" $lblue) [$(pc ' ✓ ' $green)] $1\n"
}

function subfolder_title() {
  _add_boxline
  # _newline
  _add_whitespaces 1

  pc "$1" "$bold"

  _add_whitespaces 1
  pc "$2" "$normal$yellow"
}

function _print_link_result() {
  _add_boxline
  _add_whitespaces 1

  _success
  _add_whitespaces 1
  pc "$1"
}


function _echo_already_linked_files() {
  _add_boxline
  # _newline
  _add_whitespaces 1

  _success
  _add_whitespaces 1

  pc "$1" "$cyan$bold"
  _add_whitespaces 1

  pc "files"
  _add_whitespaces 1

  pc "already linked" "$dgray$uline"
}
