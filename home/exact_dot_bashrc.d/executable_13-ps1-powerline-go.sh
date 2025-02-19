#!/usr/bin/env bash

POWERLINE_GO_BASH_ENABLED=true # option to enable/disable powerline shell (reload the terminal after change)
if [[ $POWERLINE_GO_BASH_ENABLED == "true" ]] && [ -x "$(command -v powerline-go)" ]; then
  # export POWERLINE_BASH_CONTINUATION=1
  # export POWERLINE_BASH_SELECT=1
  # . /usr/share/powerline/bash/powerline.sh
  function _update_ps1() {
    PS1="$(powerline-go -modules ssh,cwd,git,hg,jobs,root,exit \
      -error $? \
      -jobs "$(jobs -p | wc -l)")"
    # TESTVAR=$(echo "some \
    # #   xxx\
    # #   text\
    # #   ")
    # PS1=$(powerline-go -error $? -modules "git" -colorize-hostname)
    # echo "test"
    # PS1="$(powerline-go -error $? -jobs $(jobs -p | wc -l))"

    # Uncomment the following line to automatically clear errors after showing
    # them once. This not only clears the error for powerline-go, but also for
    # everything else you run in that shell. Don't enable this if you're not
    # sure this is what you want.

    #set "?"
    # echo $TESTVAR
  }

  if [ "$TERM" != "linux" ]; then
    PROMPT_COMMAND="_update_ps1; $PROMPT_COMMAND"
  fi

fi


# # Set powerline-go theme
# export POWERLINE_GO_THEME="default"
#
# # Disable true color if required
# export POWERLINE_GO_TERM_TRUECOLOR=0
#
# # Define powerline-go prompt
# function _update_ps1() {
#     PS1=$(powerline-go -error $? \
#         -modules "ssh, cwd, git, hg, jobs, root, exit" \
#         -colorize-hostname)
# }
#
# # Set PROMPT_COMMAND to call the prompt update
# if [ "$TERM" != "linux" ]; then
#     PROMPT_COMMAND="_update_ps1; $PROMPT_COMMAND"
# fi
