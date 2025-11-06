#!/usr/bin/env bash
#
# Configure Mise

if which mise >/dev/null; then
  # https://mise.jdx.dev/installing-mise.html#autocompletion
  # This requires bash-completion to be installed
  #
  eval "$(mise activate bash)"
  if ! which usage >/dev/null; then
    echo "Usage (for mise) is not installed, installing it now..."
    mise use --global usage
  fi
  mkdir -p "${HOME}/.local/share/bash-completion/completions/"
  mise completion bash --include-bash-completion-lib > "${HOME}/.local/share/bash-completion/completions/mise"
fi
