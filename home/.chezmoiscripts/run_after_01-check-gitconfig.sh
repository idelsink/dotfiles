#!/usr/bin/env bash
#
# Check if the current git config (and pgp key) will have any issues

output="$(${CHEZMOI_WORKING_TREE}/bin/check-git-pgp-user-email.sh 2>&1)"
exit_code=$?

if [[ $exit_code -ne 0 ]]; then
  echo "${output}"
fi
