#!/usr/bin/env bash
#
# Utility script to manage a pgp (sub)key.

: ${ACTION:=""}
: ${KEY_EXPIRATION:="1y"}
: ${KEY_FINGERPRINT:=""}
: ${SUBKEY_FINGERPRINT:=""}

print_usage() {
  echo "Usage: ${0} [OPTIONS]"
  echo
  echo "Utility to manage GPG (sub)keys."
  echo
  echo "Required options:"
  echo "  -a, --action  What action to perform. (default: '${ACTION}')"
  echo "                  * import-from-keybase    : Import <FINGERPRINT> from Keybase to GPG"
  echo "                  * import-from-keybase-fs : Import <FINGERPRINT> from Keybase Filesystem to GPG"
  echo "                  * export-to-keybase      : Export <FINGERPRINT> from GPG to Keybase"
  echo "                  * export-to-keybase-fs   : Export <FINGERPRINT> from GPG to Keybase Filesystem"
  echo "                  * isolate-subkey         : Remove primary <FINGERPRINT> and keep only <SUBKEY>"
  echo "                  * generate-subkey        : Generate a new subkey for <FINGERPRINT> with <EXPIRATION>"
  echo "                  * set-subkey-expiration  : Update expiration for <FINGERPRINT>'s <SUBKEY> with <EXPIRATION>"
  echo
  echo "Optional options:"
  echo "  -f, --fingerprint=<FINGERPRINT>     primary key fingerprint."
  echo "  -s, --sub-fingerprint=<FINGERPRINT> subkey fingerprint."
  echo "  -e, --expiration=<EXPIRATION>       expiration for key (generated or updated). (default: '${KEY_EXPIRATION}') See also: https://www.gnupg.org/documentation/manuals/gnupg/OpenPGP-Key-Management.html"
  echo "  -h, --help                          print help"
  echo
  echo "Examples:"
  echo "  \$ ${0} -a export-to-keybase -f 40157412895F2634C4409E77C36EC45D885B9E3F"
  echo
  echo "  \$ ${0} -a import-from-keybase -f 40157412895F2634C4409E77C36EC45D885B9E3F"
  echo
  echo "  \$ ${0} -a isolate-subkey -f 40157412895F2634C4409E77C36EC45D885B9E3F -s A8E334E037A84CFAA404BD85E4DEDF6F2258281A"
  echo
  echo "  \$ ${0} -a generate-subkey -e 2y"
  echo
  echo "  \$ ${0} -a set-subkey-expiration -f 40157412895F2634C4409E77C36EC45D885B9E3F -s A8E334E037A84CFAA404BD85E4DEDF6F2258281A -e 2y"
}

while getopts 'a:e:f:hs:-:' OPT; do # Make sure to keep the last '-:' as this is for long options
  # support long options: https://stackoverflow.com/a/28466267/519360
  if [ "${OPT}" = "-" ]; then   # long option: reformulate OPT and OPTARG
    OPT="${OPTARG%%=*}"       # extract long option name
    OPTARG="${OPTARG#"${OPT}"}" # extract long option argument (may be empty)
    OPTARG="${OPTARG#=}"      # if long option argument, remove assigning `=`
  fi
  case "$OPT" in
    a | action          ) ACTION="${OPTARG}" ;;
    e | expiration      ) KEY_EXPIRATION="${OPTARG}" ;;
    f | fingerprint     ) KEY_FINGERPRINT="${OPTARG}" ;;
    h | help            ) print_usage; exit 0 ;;
    s | sub-fingerprint ) SUBKEY_FINGERPRINT="${OPTARG}" ;;
    \?                  ) exit 2 ;; # bad short option (error reported via getopts)
    *                   ) echo "Illegal option --${OPT}" ;; # bad long option
  esac
done

# Prompt the user to continue with the execution
# Arguments:
#   $1 - (optional) message to print to the user
# shellcheck disable=SC2120 # Ignoring https://github.com/koalaman/shellcheck/wiki/SC2120 - foo references arguments, but none are ever passed.
prompt_continue() {
  local prompt_message="${1:-""}"
  if [[ -n "${prompt_message}" ]]; then
    read -p "${prompt_message} (Press Enter to continue...)"
  else
    read -p "(Press Enter to continue...)"
  fi
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

# Checks if all specified commands exist in PATH.
# Arguments:
#   $@ - List of command names to check.
# Returns:
#   Exits with code 1 if any command is missing.
required_commands() {
  local missing=()
  while [[ $# -gt 0 ]]; do
    command -v "${1}" &>/dev/null || missing+=("${1}")
    shift
  done
  if [[ ${#missing[@]} -gt 0 ]]; then
    echo "Error: Missing required commands: ${missing[*]}"
    exit 1
  fi
}

# Validates that required variables are set with non-empty values.
# Arguments:
#   Variable pairs: VAR_NAME "option_display_name"
# Example:
#   validate_required_variables KEY_ID "--key-id" NAME "--name"
# Returns:
#   Exits with code 1 if any required variable is empty.
validate_required_variables() {
  local missing_args=()
  while [[ $# -gt 0 ]]; do
    local var_name="${1}"
    local option_name="${2}"
    shift 2
    if [[ -z "${!var_name}" ]]; then
      missing_args+=("${option_name}")
    fi
  done
  if [[ ${#missing_args[@]} -gt 0 ]]; then
    echo "Error: Missing required options: ${missing_args[*]}"
    exit 1
  fi
}

# Retrieves the current Keybase username, prompting for login if needed.
# Arguments:
#   $1 - (Optional) Variable name to store the Keybase username into
# Example:
#   get_keybase_user KEYBASE_USER
#   echo "Logged in as: $KEYBASE_USER"
# Returns:
#   0 on Successfully retrieved username and 1 on User declined to login
#   Exits with code 1 on login failure
get_keybase_user() {
  local -n user # Declare but don't assign yet
  # Only assign if $1 is provided
  if [[ -n "${1}" ]]; then
    user="${1}"
  fi

  # Try to get current user first
  # shellcheck disable=SC2034 # Used as nameref
  if user=$(keybase whoami 2>/dev/null); then
    return 0
  fi

  echo "You're not logged in into keybase."
  if ! prompt_yes_no "Do you want to login?"; then
    echo "Login canceled."
    exit 1
  fi

  if ! keybase login; then
    echo "Something went wrong."
    exit 1
  fi

  # Recursive call after successful login
  get_keybase_user "${1}" # Passing $1 again as this is a recursive call and we cant reuse the nameref
  return $?
}

# Validates the gpg key KEY_FINGERPRINT for exporting
# Returns:
#   0 on success
#   Exits with code 1 on key failure
function validate_gpg_keys() {
  echo
  echo "✔️ Validate GPG key - This will check for gnu-dummy keys"
  echo "    Primary      : ${KEY_FINGERPRINT}"
  echo "    Get ready to enter your Primary key password"
  prompt_continue

  local keys=$(gpg --armor --export-secret-keys "${KEY_FINGERPRINT}")

  # Check if export produced any content
  if [[ -z "${keys}" ]]; then
    echo "❌ Error: No secret keys found for ${KEY_FINGERPRINT}"
    exit 1
  fi

  # Check for dummy subkeys
  if echo "${keys}" | gpg --list-packets | grep -q "gnu-dummy"; then
    echo "❌ Error: Key contains dummy subkeys. Cannot export incomplete key."
    echo "   Please restore complete key with all subkey secrets first."
    exit 1
  fi
}

case "${ACTION}" in
  import-from-keybase)
    validate_required_variables KEY_FINGERPRINT "--fingerprint"
    required_commands gpg keybase
    keybase_user=""
    get_keybase_user keybase_user
    echo
    echo "📥 Download and import from keybase"
    echo "    Keybase User : ${keybase_user}"
    echo "    Primary      : ${KEY_FINGERPRINT}"
    echo "    Get ready to enter your Primary key password 2-3 times"
    prompt_continue
    # Import the public keys
    keybase pgp export --query "${KEY_FINGERPRINT}" | gpg --import --quiet
    # Set ownertrust to max level
    echo "${KEY_FINGERPRINT}:6:" | gpg --import-ownertrust
    # Import the private keys
    keybase pgp export --secret --query "${KEY_FINGERPRINT}" | gpg --batch --allow-secret-key-import --import
    gpg --list-secret-keys --keyid-format LONG "${KEY_FINGERPRINT}"
    ;;
  import-from-keybase-fs)
    validate_required_variables KEY_FINGERPRINT "--fingerprint"
    required_commands gpg keybase
    keybase_user=""
    get_keybase_user keybase_user
    echo
    echo "📥 Download and import from Keybase Filesystem"
    echo "    Keybase User : ${keybase_user}"
    echo "    Primary      : ${KEY_FINGERPRINT}"
    echo "    Get ready to enter your Primary key password 2-3 times"
    prompt_continue
    # Import the public keys
    keybase pgp export --query "${KEY_FINGERPRINT}" | gpg --import --quiet
    # Set ownertrust to max level
    echo "${KEY_FINGERPRINT}:6:" | gpg --import-ownertrust
    # Import the private keys
    keybase pgp pull-private --force "${KEY_FINGERPRINT}"
    gpg --list-secret-keys --keyid-format LONG "${KEY_FINGERPRINT}"
    ;;

  export-to-keybase)
    validate_required_variables KEY_FINGERPRINT "-f, --fingerprint"
    required_commands gpg keybase
    validate_gpg_keys
    keybase_user=""
    get_keybase_user keybase_user
    echo
    echo "📤 Export and upload to Keybase"
    echo "    Keybase User : ${keybase_user}"
    echo "    Primary      : ${KEY_FINGERPRINT}"
    echo "    Get ready to enter your:"
    echo "      * Primary key password 2 times and"
    echo "      * your Keybase password."
    prompt_continue
    # Update the public keys
    keybase pgp update "${KEY_FINGERPRINT}"
    # Export the private keys to keybase
    gpg --export-secret-keys "${KEY_FINGERPRINT}" | keybase pgp import --push-secret
    ;;

  export-to-keybase-fs)
    validate_required_variables KEY_FINGERPRINT "-f, --fingerprint"
    required_commands gpg keybase
    validate_gpg_keys
    keybase_user=""
    get_keybase_user keybase_user
    echo
    echo "📤 Export and upload to Keybase Filesystem"
    echo "    Keybase User : ${keybase_user}"
    echo "    Primary      : ${KEY_FINGERPRINT}"
    echo "    Get ready to enter your:"
    echo "      * Primary key password 2 times and"
    echo "      * your Keybase password."
    prompt_continue
    # Update the public keys
    keybase pgp update "${KEY_FINGERPRINT}"
    # Push they key to keybase filesystem
    keybase pgp push-private --force "${KEY_FINGERPRINT}"
    ;;

  isolate-subkey)
    validate_required_variables \
      KEY_FINGERPRINT     "-f, --fingerprint" \
      SUBKEY_FINGERPRINT  "-s, --sub-fingerprint"
    required_commands gpg
    echo
    echo "🔒 Isolate subkey"
    echo "    Remove primary (private) keys and keep subkey on device"
    echo "    Primary : ${KEY_FINGERPRINT}"
    echo "    Subkey  : ${SUBKEY_FINGERPRINT}"
    echo "   Get ready to enter your Primary key password 2 times"
    echo "     1. Unlock and export subkey"
    echo "     2. Import subkey"
    prompt_continue
    exported_subkey=$(gpg --armor --export-secret-subkeys "${SUBKEY_FINGERPRINT}!")
    if [[ -z "${exported_subkey}" ]]; then
      echo "Error: Failed to export the subkey. Exiting."
      exit 1
    fi
    if prompt_yes_no "❗ Are you sure you want to delete all private keys for ${KEY_FINGERPRINT} (including the primary key)?"; then
      gpg --delete-secret-keys "${KEY_FINGERPRINT}"
      echo "✅ Private keys deleted"
    else
      echo "❌ Operation canceled."
      exit 1
    fi
    echo "${exported_subkey}" | gpg --import --quiet
    # Set ownertrust to max level
    echo "${KEY_FINGERPRINT}:6:" | gpg --import-ownertrust
    echo "✅ Subkey imported successfully!"
    echo
    gpg --list-secret-keys --keyid-format LONG "${KEY_FINGERPRINT}"
    ;;

  generate-subkey)
    validate_required_variables KEY_FINGERPRINT "-f, --fingerprint"
    required_commands gpg
    echo
    echo "🆕 Generate a new subkey"
    echo "    Primary : ${KEY_FINGERPRINT}"
    echo "    Expiry  : ${KEY_EXPIRATION}"
    prompt_continue
    gpg --batch \
        --quiet \
        --quick-add-key "${KEY_FINGERPRINT}" ed25519 "sign,auth" "${KEY_EXPIRATION}"
    echo
    gpg --list-secret-keys --keyid-format LONG "${KEY_FINGERPRINT}"
    ;;

  set-subkey-expiration)
    validate_required_variables \
      KEY_FINGERPRINT     "-f, --fingerprint" \
      SUBKEY_FINGERPRINT  "-s, --sub-fingerprint"
    required_commands gpg
    echo
    echo "⏳ Update expiration for subkey"
    echo "    Primary : ${KEY_FINGERPRINT}"
    echo "    Subkey  : ${SUBKEY_FINGERPRINT}"
    echo "    Expiry  : ${KEY_EXPIRATION}"
    echo "   Get ready to enter your Primary key password"
    prompt_continue
    gpg --batch \
      --quick-set-expire "${KEY_FINGERPRINT}" "${KEY_EXPIRATION}" "${SUBKEY_FINGERPRINT}"
    echo
    gpg --list-secret-keys --keyid-format LONG "${KEY_FINGERPRINT}"
    ;;

  *)
    echo "Error: Unknown action '${ACTION}'"
    echo
    print_usage
    exit 1
    ;;
esac
