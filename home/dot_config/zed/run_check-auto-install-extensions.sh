#!/usr/bin/env bash
#
# Simple script to check if the installed extensions are listed in the auto_install_extensions Zed settings file

ZED_SETTINGS="${PWD}/settings.json"
EXTENSIONS_DIR="${HOME}/.local/share/zed/extensions/installed"

if [[ ! "${CHEZMOI_OS}" == "linux" ]]; then
  echo "Error: OS ${CHEZMOI_OS} is not supported by $0." >&2
  exit 1
fi

if ! command -v jq &>/dev/null ]; then
  exit 0
fi

auto_install_extensions=$(cat ~/.config/zed/settings.json | sed 's/^ *\/\/.*//' | jq '.auto_install_extensions // [] | keys')
missing_extensions=()

for ext_dir in "${EXTENSIONS_DIR}"/*; do
  if [[ -d "${ext_dir}" ]]; then
    ext_name=$(basename "${ext_dir}")

    # If the extension is not in the auto_install_extensions list, add it to the missing list
    if [[ ! "${auto_install_extensions}" =~ "${ext_name}" ]]; then
      missing_extensions+=("${ext_name}")
    fi
  fi
done

if [[ ! ${#missing_extensions[@]} -eq 0 ]]; then
  echo "Found ${#missing_extensions[@]} Zed extensions that are not in your config file:"
  for ext in "${missing_extensions[@]}"; do
    echo "  - ${ext}"
  done

  echo
  echo "Add these extensions to your auto_install_extensions in ${ZED_SETTINGS}:"
  echo '"auto_install_extensions": ['
  for ext in "${missing_extensions[@]}"; do
    echo "  \"$ext\": true,"
  done
  echo "]"
fi
