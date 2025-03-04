#!/usr/bin/env bash
#
# Script that uses crudini to loop all the keys of each section and then
#   1. Reads the current value for that section/key from the dconf database
#   2. Writes it back into the config file (changed dconf values will then overwrite the current value)

dconf_file="dconf.ini"

if [[ ! -f "${dconf_file}" ]]; then
  # File does not exist, so nothing to export
  exit 0
fi

for section in $(crudini --get "${dconf_file}" 2>/dev/null); do
  for key in $(crudini --get "${dconf_file}" "${section}" 2>/dev/null); do
    dconf_value=$(dconf read "/${section}/${key}")
    crudini --set "${dconf_file}" "${section}" "${key}" "${dconf_value}"
  done
done
