#!/usr/bin/env bash
#
# Script that loads the dconf compatible keyfile

if ! command -v dconf &> /dev/null; then
  # dconf is not found, assuming dconf is not used on this system
  exit 0
fi

if ! command -v crudini &> /dev/null; then
  echo "Could not find command crudini, exiting..."
  exit 1
fi

dconf_file="dconf.ini"

if [[ ! -f "${dconf_file}" ]]; then
  # File does not exist, so nothing to import
  exit 0
fi

backup_dir="dconf-backups"

backup_file="$backup_dir/dconf-backup-$(date +%Y%m%d-%H%M%S).ini"
dconf dump / > "$backup_file"

dconf load / < "${dconf_file}"
