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

# Backup dconf before loading it in
backup_dir="dconf-backups"
previous_backup_file=$(find dconf-backups -name "dconf-backup-*.ini" -type f | sort -nr | head -1)
current_backup_file="${backup_dir}/dconf-backup-$(date +%Y-%m-%dT%H%M%S).ini"

dconf dump / > "${current_backup_file}"

if [[ -f "${previous_backup_file}" ]]; then
  if diff -q "${current_backup_file}" "${previous_backup_file}" &> /dev/null; then
    # Files are identical, remove the older backup (keeping the new one)
    rm "${previous_backup_file}"
  fi
fi

# Load dconf
dconf load / < "${dconf_file}"
