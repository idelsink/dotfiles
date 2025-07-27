#!/usr/bin/env bash
#
# Configure the Bash PS1 variable

# Option to enable/disable individual PS1 options (and fallbacks)
POWERLINE_GO_BASH_ENABLED=true
POWERLINE_BASH_ENABLED=true
DEFAULT_PS1_BASH_ENABLED=true

# Configure PS1 options with fallbacks
if [[ -x "$(command -v powerline-go)" ]] && [[ "${POWERLINE_GO_BASH_ENABLED}" == "true" ]]; then
  # powerline-go - https://github.com/justjanne/powerline-go
  function _update_ps1() {
    PS1="$(powerline-go \
      -modules ssh,cwd,git,hg,jobs,root,exit \
      -cwd-max-depth 1 \
      -cwd-mode fancy \
      -git-mode fancy \
      -mode patched \
      -newline \
      -error $? \
      -jobs "$(jobs -p | wc -l)")"
  }
  if [ "${TERM}" != "linux" ]; then
    PROMPT_COMMAND="_update_ps1; ${PROMPT_COMMAND}"
  fi
elif [[ -x "$(command -v powerline-daemon)" ]] && [[ "${POWERLINE_BASH_ENABLED}" == "true" ]]; then
  # powerline - https://powerline.readthedocs.io/en/master/index.html
  powerline-daemon -q
  export POWERLINE_BASH_CONTINUATION=1
  export POWERLINE_BASH_SELECT=1

  # Check for powerline files in order of preference
  if [ -f /usr/share/powerline/bindings/bash/powerline.sh ]; then
    source /usr/share/powerline/bindings/bash/powerline.sh
  elif [ -f /usr/share/powerline/bash/powerline.sh ]; then
    source /usr/share/powerline/bash/powerline.sh
  else
    echo "Error: No powerline script found in any of the expected locations" >&2
  fi
elif [[ $DEFAULT_PS1_BASH_ENABLED == "true" ]]; then
  # Simple fallback that shows the git branch when possible
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
