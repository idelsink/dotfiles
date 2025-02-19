#!/usr/bin/env bash

POWERLINE_BASH_ENABLED=false # option to enable/disable powerline shell (reload the terminal after change)
if [[ $POWERLINE_BASH_ENABLED == "true" ]] && [ -x "$(command -v powerline-daemon)" ]; then
  powerline-daemon -q
  export POWERLINE_BASH_CONTINUATION=1
  export POWERLINE_BASH_SELECT=1
  . /usr/share/powerline/bash/powerline.sh
fi
