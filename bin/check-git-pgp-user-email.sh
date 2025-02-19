#!/usr/bin/env bash
#
# Utility script to check if the git config user.email is matching the gitconfig pgp user.signingkey
# When user.email or user.signingkey is not set, it will assume this is intentional

GPG_FORMAT=$(git config gpg.format)

if [[ -n "${GPG_FORMAT}" && "${GPG_FORMAT}" != "openpgp" ]]; then
  echo "Git is not using a GPG key for signing (gpg.format=${GPG_FORMAT})."
  exit 0
fi

GIT_EMAIL=$(git config user.email)
if [[ -z "${GIT_EMAIL}" ]]; then
  echo "No email configured in Git."
  exit 0
fi

GIT_SIGNINGKEY=$(git config user.signingkey)
if [[ -z "${GIT_SIGNINGKEY}" ]]; then
  echo "No signing key configured in Git."
  exit 0
fi

# If the key has '!' at the end, remove it
GIT_SIGNINGKEY="${GIT_SIGNINGKEY%!}"

# GPG outputs data in a structured format using "--with-colons", where each line starts with a record type, see example:
# (e.g., "pub" for the primary key, "sub" for subkeys, "fpr" for fingerprints, etc.).
# For output format see:
# - https://git.gnupg.org/cgi-bin/gitweb.cgi?p=gnupg.git;a=blob;f=doc/DETAILS;h=470497dcd7bf87011d136a2be36fac86dcfe5cda;hb=HEAD
# - or: https://github.com/gpg/gnupg/blob/master/doc/DETAILS

# Find the primary key if this is a subkey
PRIMARY_KEY=$(gpg --with-colons --list-keys "${GIT_SIGNINGKEY}" | awk -F: '$1 == "fpr" {print $10; exit}')
# Use the primary key if found, otherwise fallback to the given key
KEY_TO_CHECK="${PRIMARY_KEY:-${GIT_KEY}}"
# Get emails associated with the primary PGP key (Field 10 - User-ID)
PGP_EMAILS=$(gpg --list-keys --with-colons "${KEY_TO_CHECK}" | awk -F: '$1 == "uid" {print $10}')

if [[ -z "${PGP_EMAILS}" ]]; then
  echo "No email addresses found for PGP key ${KEY_TO_CHECK}."
  exit 0
fi

# Check if Git email is in the PGP key's associated emails
if [[ "${PGP_EMAILS}" == *"${GIT_EMAIL}"* ]]; then
  echo "Git email (${GIT_EMAIL}) is associated with PGP key ${KEY_TO_CHECK}."
  exit 0
else
  echo "Git email (${GIT_EMAIL}) is NOT associated with PGP key ${KEY_TO_CHECK}."
  echo "This may lead to git commits being listed as unverified!"
  exit 1
fi
