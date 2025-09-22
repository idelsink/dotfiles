#!/usr/bin/env bash
#
# Configure Mise

if [[ -x "$(command -v mise)" ]]; then
  eval "$(mise activate bash)"
fi
