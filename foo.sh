#!/bin/bash

# _foo()
# {
#     local cur prev opts
#     COMPREPLY=()
#     cur="${COMP_WORDS[COMP_CWORD]}"
#     prev="${COMP_WORDS[COMP_CWORD-1]}"
#     opts="--help --verbose --version"

#     if [[ ${cur} == -* ]] ; then
#         COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
#         return 0
#     fi
# }

# complete -F _foo foo

function _run {
  if [ -z "$1" ]; then
    echo 'No options passed'
    exit
  fi

  echo "${1} option passed"
}

# _foo_completions()
# {
#   COMPREPLY+=("sync")
#   COMPREPLY+=("install")
# }

# _run "$1"
