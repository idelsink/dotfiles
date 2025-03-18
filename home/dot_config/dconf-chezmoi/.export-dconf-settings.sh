#!/usr/bin/env bash
#
# Script that uses crudini to loop all the keys of each section and then
#   1. Reads the current value for that section/key from the dconf database
#   2. Writes it back into the config file (changed dconf values will then overwrite the current value)

if ! command -v dconf &> /dev/null; then
  # dconf is not found, assuming dconf is not used on this system
  exit 0
fi

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

for dconf_file in "${target_file}" "$@"; do
  if [[ -f "${dconf_file}" ]]; then
    # Loop all dconf keys using the crudini lines output
    # This greatly speeds up the looping over all the keys instead of a nested sections and keys loop
    while read -r line; do
      # Each crudini line is formatted as:
      #
      # [ section-header-1 ] key-1 = value
      # [ section-header-1 ] key-2 = true
      # [ section-header-2 ] key-1 = 'foo'
      # [ section-header-2 ] key-2 = 'bar'
      # ...
      #
      # See: https://github.com/pixelb/crudini/blob/9657a5b046c6d30b36e8dabc707021289fe11514/crudini.py#L377
      #
      # Apply regex to each line (https://tldp.org/LDP/abs/html/x17129.html) to extract section, key and value
      regex="^\[[[:space:]](.*)[[:space:]]\][[:space:]](.*)[[:space:]]=[[:space:]](.*)$"
      if [[ "${line}" =~ $regex ]]; then
        section="${BASH_REMATCH[1]}"
        key="${BASH_REMATCH[2]}"
        # value="${BASH_REMATCH[3]}" # Value is not used as we will fetch the value from dconf
        key_path="${section}/${key}"

        if [[ -z "${processed_dconf_keys[${key_path}]}" ]]; then
          dconf_value=$(dconf read "/${key_path}")
          processed_dconf_keys["${key_path}"]="true" # Mark as processed
          # Appending command to arguments array (to speedup write back)
          # crudini --ini-options=nospace --set "$target_file" "$section" "$key" "$dconf_value"
          crudini_args+=("--set" "${target_file}" "${section}" "${key}" "${dconf_value}")
        fi
      fi
    done < <(crudini --format=lines --get "${dconf_file}")
  fi
done

# Run all crudini commands in one batch operation to speedup writebacks
if [[ ${#crudini_args[@]} -gt 0 ]]; then
  crudini --ini-options=nospace "${crudini_args[@]}"
fi
