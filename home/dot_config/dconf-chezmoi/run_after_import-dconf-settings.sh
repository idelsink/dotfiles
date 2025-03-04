#!/usr/bin/env bash
#
# Script that uses crudini to loop all the keys of each section and then
#   1. Reads the current value for that section/key from the ini file
#   2. Writes it back into the dconf system database

if ! command -v crudini &> /dev/null; then
  echo "Could not find command crudini, exiting..."
  exit 1
fi

dconf_file="dconf.ini"

if [[ ! -f "${dconf_file}" ]]; then
  # File does not exist, so nothing to import
  exit 0
fi

for section in $(crudini --get "${dconf_file}" 2>/dev/null); do
  for key in $(crudini --get "${dconf_file}" "${section}" 2>/dev/null); do
    ini_value=$(crudini --get "${dconf_file}" "${section}" "${key}" 2>/dev/null)
    dconf write "/${section}/${key}" "${ini_value}"
  done
done
