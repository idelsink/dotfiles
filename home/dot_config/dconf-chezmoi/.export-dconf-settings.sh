#!/usr/bin/env bash
#
# Script that uses crudini to loop all the keys of each section and then
#   1. Reads the current value for that section/key from the dconf database
#   2. Writes it back into the config file (changed dconf values will then overwrite the current value)

if ! command -v crudini &> /dev/null; then
  echo "Could not find command crudini, exiting..."
  exit 1
fi

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <ini_file> [additional_ini_files...]"
  exit 1
fi

# Use the first provided file as the target for writing back settings
target_file="$1"
shift  # Remove the first file from the arguments list

if [[ ! -f "${target_file}" ]]; then
  # File does not exist, so nothing to export
  exit 0
fi

declare -A processed_dconf_keys # Hash map to track processed keys
crudini_args=() # Array of crudini commands in format of --set <file> <section> <key> <value>

for dconf_file in "$target_file" "$@"; do
  # Export all settings from dconf
  for section in $(crudini --get "$dconf_file" 2>/dev/null); do
    for key in $(crudini --get "$dconf_file" "$section" 2>/dev/null); do
      key_path="$section/$key"

      # Check if already processed
      if [[ -z "${processed_dconf_keys[$key_path]}" ]]; then
        dconf_value=$(dconf read "/$key_path")
        processed_dconf_keys["$key_path"]="true" # Mark as processed
        # Appending command to arguments array (to speedup write back)
        # crudini --ini-options=nospace --set "$target_file" "$section" "$key" "$dconf_value"
        crudini_args+=("--set" "$target_file" "$section" "$key" "$dconf_value")
      fi
    done
  done
done

# Run all crudini commands in one batch operation to speedup writebacks
if [[ ${#crudini_args[@]} -gt 0 ]]; then
  crudini --ini-options=nospace "${crudini_args[@]}"
fi
