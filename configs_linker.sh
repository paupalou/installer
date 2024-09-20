#!/bin/bash

function _link_file {
  local src=$1 dst=$2 print_each_skipped_file=$4
  local overwrite backup skip action

  if [ -f "$dst" -o -d "$dst" ]; then

    if [ "$overwrite_all" == "false" ] && [ "$backup_all" == "false" ] && [ "$skip_all" == "false" ]; then
      local currentSrc="$(readlink $dst)"
      if [ "$currentSrc" == "$src" ]; then
        if [ "$print_each_skipped_file" != "false" ]; then
          _print_link_result "skipped ${cyan}$src${normal}" "$3"
        fi
        return
      else

        user "${bold}$dst${normal} already exists, what to do?"
        user_option "[${bold}s${normal}]kip ───────────── [${bold}S${normal}]kip all"
        user_option "[${bold}o${normal}]verwrite ──────── [${bold}O${normal}]verwrite all"
        user_option "[${bold}b${normal}]ackup ─────────── [${bold}B${normal}]ackup all?"
        read -n 1 action

        case "$action" in
          o)
            overwrite=true
            ;;
          O)
            overwrite_all=true
            ;;
          b)
            backup=true
            ;;
          B)
            backup_all=true
            ;;
          s)
            skip=true
            ;;
          S)
            skip_all=true
            ;;
          *) ;;

        esac
      fi
    fi

    overwrite=${overwrite:-$overwrite_all}
    backup=${backup:-$backup_all}
    skip=${skip:-$skip_all}

    if [ "$overwrite" == "true" ]; then
      rm -rf "$dst"
      _print_link_result "removed ${cyan}$dst${normal}" "$3"
      ((file_counter -= 1))
    fi

    if [ "$backup" == "true" ]; then
      mv "$dst" "${dst}.backup"
      _print_link_result "moved   ${cyan}$dst${normal} to ${dst}.backup" "$3"
      ((file_counter -= 1))
    fi

    if [ "$skip" == "true" ]; then
      _print_link_result "skipped ${cyan}$src${normal}" "$3"
    fi
  fi

  if [ "$skip" != "true" ]; then
    ln -s "$src" "$dst"
    _print_link_result "linked ${lgreen}$2${normal} -> $src" "$3"
    ((file_counter -= 1))
  fi
}

function subfolder_files {
  local topic=$1
  local subfolder=$2
  local absolute_path=$(pwd)/$topic/$subfolder
  # verbose is true by default and only applies to 'skip' action
  local verbose=${3:-'true'}

  # contains number of files skipped and used only when verbose is false
  local file_counter=0

  local overwrite_all=false backup_all=false skip_all=false
  for src in $(find -H $absolute_path -type f ! -name "*:*" ! -path "*/.git/*" -printf '%P\n'); do
    local file_name=$(basename "${src}")
    local destiny_file_name=$file_name
    local src_dirname="$(dirname "$src")"
    local child_visual_line="──"

    local matching_file=$(_grab_file $absolute_path/$src)

    # if we find symlink in first level assume src is 1st-child of $subfolder
    # so we unset src_dirname to avoid adding a dot (.)
    if [ $(dirname "$src") == "." ]; then
      src_dirname=""
    fi

    local destiny_directory="$HOME/.$subfolder/$src_dirname"
    ((file_counter += 1))

    # check if destiny directory exists , create if not
    if [ ! -d $destiny_directory ]; then
      warn "creating directory → $destiny_directory${normal}" '──'
      mkdir -p "$destiny_directory"
      # double visual line to make visual appearance as child of this directory
      child_visual_line="──────"
    fi

    destiny="$destiny_directory/$destiny_file_name"
    _link_file $matching_file $destiny "$child_visual_line" "$verbose"
  done

  if [ $verbose == "false" ] && [ $file_counter -gt 0 ]; then
    # _print_link_result "skipped ${cyan}$file_counter${normal} files" "$child_visual_line"
    _echo_already_linked_files "$file_counter" "$child_visual_line"
  fi
}

function _not_match {
  for i in ${@}; do
    echo ! -name $i
  done
}

function _symlink_files {
  _start 'linking dotfiles'

  local excluded_files=("path.fish")
  local exclude_file_list=$(_not_match ${excluded_files[@]})
  local dotfiles=$(pwd)

  local files=$(find -H $dotfiles -mindepth 2 -maxdepth 2 -type f ! -name "*:*" ! -path "*/.git/*" ! -path "*/script/*" $exclude_file_list)
  # local files=$(find -H $dotfiles -mindepth 2 -type f ! -name "*:*" ! -path "*/.git/*" ! -path "*/script/*" $exclude_file_list)
  local overwrite_all=false backup_all=false skip_all=false

  # local topics=$(find -H $dotfiles -mindepth 1 -maxdepth 1 -type d ! -path "*/.git" ! -path "*/script")

  for src in $files; do
    local file_name=$(basename $src)
    local src_dirname=$(dirname $src)
    local destiny=$HOME/.$file_name

    local matching_file=$(_grab_file $src_dirname/$file_name)

    _link_file $matching_file $destiny
  done

  for src in $(find $(pwd) -mindepth 2 -maxdepth 2 ! -path "*/.git/*" ! -path "*/script/*" -type d -printf '%P\n' | sort); do
    local topic=$(dirname "$src")
    local subfolder=$(basename "$src")

    # print a title of this subfolder
    subfolder_title $topic $subfolder

    # link files inside subfolders
    # last argument is verbose, if you pass false a compact message will be printed
    subfolder_files $topic $subfolder false
  done

  _end
}
