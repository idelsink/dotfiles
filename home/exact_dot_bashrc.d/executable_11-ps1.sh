#!/usr/bin/env bash

DEFAULT_PS1_BASH_ENABLED=false # option to enable/disable powerline shell (reload the terminal after change)
if [[ $DEFAULT_PS1_BASH_ENABLED == "true" ]]; then

  function print_git_color {
    local git_status
    git_status="$(git status 2> /dev/null)"

    case "${git_status}" in
      *"Changes to be committed:"*)
        if [[ "${git_status}" =~ "Untracked files:" ]]; then
          echo -e "$(print_ansi_escape_sequence green)"; # some files staged
        else
          echo -e "$(print_ansi_escape_sequence bright_green)"; # all files stagged
        fi
        ;;
      *"Your branch is ahead of"*)
        echo -e "$(print_ansi_escape_sequence yellow)";
        ;;
      *"Changes not staged for commit:"*)
        echo -e "$(print_ansi_escape_sequence bright_red)";
        ;;
      *"Untracked files:"*)
        echo -e "$(print_ansi_escape_sequence bright_green)";
        ;;
      *"nothing to commit, working directory clean"*)
        echo -e "$(print_ansi_escape_sequence white)";
        ;;
      *)
        echo -e "$(print_ansi_escape_sequence gray)";
        ;;
    esac
  }
  function git_branch {
    local git_status
    git_status="$(git status 2> /dev/null)"
    local on_branch="On branch ([^${IFS}]*)"
    local on_commit="HEAD detached at ([^${IFS}]*)"

    if [[ $git_status =~ $on_branch ]]; then
      local branch=${BASH_REMATCH[1]}
      echo "($branch)"
    elif [[ $git_status =~ $on_commit ]]; then
      local commit=${BASH_REMATCH[1]}
      echo "($commit)"
    fi
  }

  # PS1
  # [user@host workdir-basename](git repo)$
  # PS1="[\u@\h \W]"
  # [workdir-basename]
  PS1="[\W]"
  PS1+="\[\$(print_git_color)\]" # colors git status
  PS1+="\$(git_branch)" # prints current branch
  PS1+="\[$(print_ansi_escape_sequence reset)\]"
  PS1+="\$ "

fi
