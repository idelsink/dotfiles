#!/usr/bin/env bash
#
# Script to provision a pgp subkey on device, see print_usage for more info.

: ${KEY_EXPIRATION_THRESHOLD:="2 months"}
: ${KEY_EXPIRATION:="1y"}
: ${KEY_FINGERPRINT:=""}
: ${QUIET_ON_SUCCESS:="false"}

print_usage() {
  echo "Usage: ${0} [OPTIONS]"
  echo "Utility script to provision an machine with a pgp subkey on a device. This can:"
  echo "  1. Downloads the primary key and add a subkey if no key is present on device"
  echo "  2. Extends the key's expiration date if it's close to expiry"
  echo
  echo "where:"
  echo
  echo "OPTIONS:"
  echo "  -e, --expiration=<EXPIRATION>           expiration for subkey when it is generated or updated. (default: '${KEY_EXPIRATION}') See also: https://www.gnupg.org/documentation/manuals/gnupg/OpenPGP-Key-Management.html"
  echo "  -f, --fingerprint=<FINGERPRINT>         primary key fingerprint"
  echo "  -h, --help                print help"
  echo "  -Q, --quiet-on-success                  suppresses any output when a valid key was found and no action is needed"
  echo "  -t, --expiration-threshold=<THRESHOLD>  expiration threshold after winch a key needs to be renewed to avoid expired keys. (default: '${KEY_EXPIRATION_THRESHOLD}')"
  echo
  echo "ENVIRONMENT VARIABLES:"
  echo "  KEY_EXPIRATION            see option: -e, --expiration=<EXPIRATION>"
  echo "  KEY_EXPIRATION_THRESHOLD  see option: -e, --expiration=<EXPIRATION>"
  echo "  KEY_FINGERPRINT           see option: -f, --fingerprint=<FINGERPRINT>"
  echo "  QUIET_ON_SUCCESS          see option: -Q, --quiet-on-success"
  echo
  echo "EXAMPLES:"
  echo "  \$ ${0} -f 40157412895F2634C4409E77C36EC45D885B9E3F"
  echo
  echo "  \$ ${0} -f 40157412895F2634C4409E77C36EC45D885B9E3F -e 5y -t '1 months'"
  echo
}

while getopts 'e:f:hQt:-:' OPT; do  # Make sure to keep the last '-:' as this is for long options
  # support long options: https://stackoverflow.com/a/28466267/519360
  if [ "${OPT}" = "-" ]; then   # long option: reformulate OPT and OPTARG
    OPT="${OPTARG%%=*}"       # extract long option name
    OPTARG="${OPTARG#"${OPT}"}" # extract long option argument (may be empty)
    OPTARG="${OPTARG#=}"      # if long option argument, remove assigning `=`
  fi
  case "${OPT}" in
    e | expiration            ) KEY_EXPIRATION="${OPTARG}" ;;
    f | fingerprint           ) KEY_FINGERPRINT="${OPTARG}" ;;
    h | help                  ) print_usage; exit 0 ;;
    Q | quiet-on-success      ) QUIET_ON_SUCCESS="true" ;;
    t | expiration-threshold  ) KEY_EXPIRATION_THRESHOLD="${OPTARG}" ;;
    \?                        ) exit 2 ;; # bad short option (error reported via getopts)
    *                         ) echo "Illegal option --${OPT}" ;; # bad long option
  esac
done

print_final_instructions() {
  echo "------------------------------------------------------------"
  echo "  Re-add the following public key to your Git providers for commit signing"
  echo
  echo "    https://keybase.io/_/api/1.0/user/lookup.json?fields=public_keys&key_fingerprint=${KEY_FINGERPRINT}"
  echo
  echo "  Git Provider Key Setup"
  echo "    * Github:     https://github.com/settings/keys"
  echo "------------------------------------------------------------"
}

get_pgp_key_detail() {
  current_dir="$(dirname "$(realpath "$0")")"
  ${current_dir}/get-pgp-key-detail.sh "$@"
}

pgp_util() {
  current_dir="$(dirname "$(realpath "$0")")"
  ${current_dir}/pgp-util.sh "$@"
}

# Prompt the user with a yes or no question
# Arguments:
#   $1 - Question to prompt to the user
#   $2 - (optional) variable to store the answer in ('true'/'false' for Yes and No respectively)
# Returns:
#   0 on Yes and 1 on No
# shellcheck disable=SC2120 # Ignoring https://github.com/koalaman/shellcheck/wiki/SC2120 - foo references arguments, but none are ever passed.
prompt_yes_no() {
  local prompt_message="${1:-""}"
  local -n password_var # Declare but don't assign yet
  # Only assign if $2 is provided
  if [[ -n "${2}" ]]; then
    password_var="${2}"
  fi

  while true; do
    if [[ -n "${prompt_message}" ]]; then
      read -r -p "${prompt_message} (y/n): " response_var
    else
      read -r -p "(y/n): " response_var
    fi

    # shellcheck disable=SC2034 # Used as nameref
    case "${response_var,,}" in
      y|yes ) password_var="true"; return 0 ;;
      n|no  ) password_var="false"; return 1 ;;
      *     ) echo "Please enter Yes (yes/y) or No (no/n)." ;;
    esac
  done
}

SUBKEY_EXPIRATION_THRESHOLD_SECONDS=$(date -d "now + $KEY_EXPIRATION_THRESHOLD" +%s)
SUBKEY_EXPIRATION_TIME=$(get_pgp_key_detail --fingerprint="${KEY_FINGERPRINT}" --detail=expiration)
SUBKEY_FINGERPRINT=$(get_pgp_key_detail --fingerprint="${KEY_FINGERPRINT}" --detail=fingerprint)
SUBKEY_ID=$(get_pgp_key_detail --fingerprint="${KEY_FINGERPRINT}" --detail=key-id)


if [[ -z "$SUBKEY_ID" ]]; then
  echo "No suitable subkey found using ${KEY_FINGERPRINT}."
  echo
  echo "Do you want to add a subkey for this machine? This means:"
  echo
  echo "  1. Downloading your primary key from Keybase"
  echo "  2. Creating a new subkey for this device"
  echo "  3. Publishing this modified primary key"
  echo "  4. Deleting the primary key and only keep the subkey on this device"

  if prompt_yes_no; then
    pgp_util --action="import-from-keybase" --fingerprint="${KEY_FINGERPRINT}"
    keys_after=$(date -d "now - 5 second" +%s) # If we start checking from now, we might be too quick and search in the same "second". This giving us some extra margin
    pgp_util --action="generate-subkey" --fingerprint="${KEY_FINGERPRINT}" --expiration="${KEY_EXPIRATION}"

    # Get newly added key
    SUBKEY_ID=$(get_pgp_key_detail --fingerprint="${KEY_FINGERPRINT}" --after="${keys_after}" --detail=key-id)
    SUBKEY_FINGERPRINT=$(get_pgp_key_detail --fingerprint="${KEY_FINGERPRINT}" --after="${keys_after}" --detail=fingerprint)
    SUBKEY_EXPIRATION_TIME=$(get_pgp_key_detail --fingerprint="${KEY_FINGERPRINT}" --after="${keys_after}" --detail=expiration)
    if [[ -z "$SUBKEY_ID" ]]; then
      echo "Something went wrong generating a new key and it could not be found"
      exit 1
    fi

    echo "Generated subkey ${SUBKEY_ID} and is valid until $(date -d @${SUBKEY_EXPIRATION_TIME} --rfc-3339=date)"
    pgp_util --action="export-to-keybase" --fingerprint="${KEY_FINGERPRINT}"
    pgp_util --action="isolate-subkey"    --fingerprint="${KEY_FINGERPRINT}" --sub-fingerprint="${SUBKEY_FINGERPRINT}"
    print_final_instructions
  else
    echo "Skipping key generation and modification..."
    exit 0
  fi
elif [[ -n "$SUBKEY_EXPIRATION_TIME" && "$SUBKEY_EXPIRATION_TIME" -lt "$SUBKEY_EXPIRATION_THRESHOLD_SECONDS" ]]; then
  echo "Valid subkey $SUBKEY_ID exist but it is (almost) expired; valid until $(date -d @$SUBKEY_EXPIRATION_TIME --rfc-3339=date)"
  echo
  echo "Do you want to update the expiration for this subkey? This means:"
  echo
  echo "  1. Downloading your primary key from Keybase"
  echo "  2. Updating the subkey for this device"
  echo "  3. Publishing this modified primary key"
  echo "  4. Deleting the primary key and only keep the subkey on this device"
  if prompt_yes_no; then
    pgp_util --action="import-from-keybase"   --fingerprint="${KEY_FINGERPRINT}"
    pgp_util --action="set-subkey-expiration" --fingerprint="${KEY_FINGERPRINT}" --sub-fingerprint="${SUBKEY_FINGERPRINT}" --expiration="${KEY_EXPIRATION}"
    pgp_util --action="export-to-keybase"     --fingerprint="${KEY_FINGERPRINT}"
    pgp_util --action="isolate-subkey"        --fingerprint="${KEY_FINGERPRINT}" --sub-fingerprint="${SUBKEY_FINGERPRINT}"
    print_final_instructions
  else
    echo "Skipping key modification..."
    exit 0
  fi
else
  if [[ "${QUIET_ON_SUCCESS}" == false ]]; then
    echo "Valid subkey $SUBKEY_ID exists and is valid until $(date -d @$SUBKEY_EXPIRATION_TIME --rfc-3339=date)"
  fi
fi
