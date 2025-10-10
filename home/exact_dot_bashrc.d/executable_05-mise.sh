#!/usr/bin/env bash
#
# Configure Mise

if [[ -x "$(command -v mise)" ]]; then
  # https://mise.jdx.dev/installing-mise.html#autocompletion
  # This requires bash-completion to be installed
  mkdir -p "${HOME}/.local/share/bash-completion/completions/"
  mise completion bash --include-bash-completion-lib > "${HOME}/.local/share/bash-completion/completions/mise"
  eval "$(mise activate bash)"
fi
