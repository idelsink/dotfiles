#!/usr/bin/env bash

: ${GENERATE_PASSWORD:="false"}
: ${SSH_CONFIG_DIR:="$HOME/.ssh"}
: ${SSH_KEY_COMMENT:="${USER}@${HOSTNAME}"}
: ${SSH_KEY_NAME:="id"}
: ${SSH_KEY_PASSWORD:=""}
: ${SSH_KEY_TYPE:="ed25519"}

print_usage() {
  echo "Usage: ${0} [OPTIONS]"
  echo "Utility script to provision an SSH key on a device:"
  echo "  1. Generates SSH key when the key does not exists (with passphrase)"
  echo "  2. Adds the key to the system keyring when it's available"
  echo "  3. Adds the key to the SSH Agent"
  echo
  echo "where:"
  echo
  echo "OPTIONS:"
  echo "  -c, --comment=COMMENT     key comment (default: '${SSH_KEY_COMMENT}')"
  echo "  -d, --directory=DIRECTORY config directory (default: '${SSH_CONFIG_DIR}')"
  echo "  -g, --generate-password   generate a password when a new key is generated."
  echo "  -h, --help                print help"
  echo "  -n, --name=NAME           key name. This will impact the location the key (default: '${SSH_KEY_NAME}')"
  echo "  -p, --password=PASSWORD   passphrase. This will be asked when not provided."
  echo "  -t, --type=TYPE           key type. (default: '${SSH_KEY_TYPE}')"
  echo
  echo "ENVIRONMENT VARIABLES:"
  echo "  GENERATE_PASSWORD Generate password when a new key is generated (default: '${GENERATE_PASSWORD}')"
  echo "  SSH_CONFIG_DIR    Path to SSH config directory (default: '${SSH_CONFIG_DIR}')"
  echo "  SSH_KEY_COMMENT   Comment for the SSH key (default: '${SSH_KEY_COMMENT}')"
  echo "  SSH_KEY_NAME      Name of the SSH key file (default: '${SSH_KEY_NAME}')"
  echo "  SSH_KEY_PASSWORD  Optional password for the SSH key (default: '${SSH_KEY_PASSWORD}')"
  echo "  SSH_KEY_TYPE      Type of SSH key to generate (default: '${SSH_KEY_TYPE}')"
  echo
  echo "EXAMPLES:"
  echo "  \$ ${0} --name=mykey --comment='myuser@myhost'"
}

# Generate a password and output to stdout
# Arguments:
#   $1 - variable to store the password in
#   $2 - (optional) Password size, defaults to 40
# Returns:
#   returns 0 (success); otherwise it returns 1
generate_password() {
  local -n password_var # Declare but don't assign yet
  # Only assign if $2 is provided
  if [[ -n "${1}" ]]; then
    password_var="${1}"
  fi
  local size="${2:-"40"}"
  # Using the OWASP password special characters list: https://owasp.org/www-community/password-special-characters
  password_var=$(tr -dc 'A-Za-z0-9!"#$%&'\''()*+,-./:;<=>?@[\]^_`{|}~' </dev/urandom | head -c "${size}");
}

# Prompt the user for a password
# Arguments:
#   $1 - variable to store the password in
# Returns:
#   0 on success, 1 on failure
prompt_for_password() {
  local -n password_var # Declare but don't assign yet
  # Only assign if $2 is provided
  if [[ -n "${1}" ]]; then
    password_var="${1}"
  fi
  if [[ -z "${password_var}" ]]; then
    read -s -p "Enter passphrase for ${ssh_key_file}: " password_var
    echo
  fi
}

while getopts 'c:d:ghn:p:t:-:' OPT; do  # Make sure to keep the last '-:' as this is for long options
  # support long options: https://stackoverflow.com/a/28466267/519360
  if [ "$OPT" = "-" ]; then   # long option: reformulate OPT and OPTARG
    OPT="${OPTARG%%=*}"       # extract long option name
    OPTARG="${OPTARG#"$OPT"}" # extract long option argument (may be empty)
    OPTARG="${OPTARG#=}"      # if long option argument, remove assigning `=`
  fi
  case "$OPT" in
    c | comment           ) SSH_KEY_COMMENT="${OPTARG}" ;;
    d | directory         ) SSH_CONFIG_DIR="${OPTARG}" ;;
    g | generate-password ) GENERATE_PASSWORD="true" ;;
    h | help              ) print_usage; exit 0 ;;
    n | name              ) SSH_KEY_NAME="${OPTARG}" ;;
    p | password          ) SSH_KEY_PASSWORD="${OPTARG}" ;;
    t | type              ) SSH_KEY_TYPE="${OPTARG}" ;;
    \?                    ) exit 2 ;; # bad short option (error reported via getopts)
    *                     ) echo "Illegal option --$OPT" ;; # bad long option
  esac
done

ssh_key_file="${SSH_CONFIG_DIR}/${SSH_KEY_NAME}_${SSH_KEY_TYPE}"

if [[ ! -f "${ssh_key_file}" ]]; then
  echo "Providing device with SSH keypair..."
  if [[ "${GENERATE_PASSWORD}" == true ]]; then
    generate_password SSH_KEY_PASSWORD
  else
    prompt_for_password SSH_KEY_PASSWORD
  fi
  ssh-keygen \
    -t "${SSH_KEY_TYPE}" \
    -f "$ssh_key_file" \
    -C "${SSH_KEY_COMMENT}" \
    -P "${SSH_KEY_PASSWORD}"

  if [[ $? -eq 0 ]]; then
    chmod 600 "${ssh_key_file}"
    chmod 644 "${ssh_key_file}.pub"
    echo "------------------------------------------------------------"
    echo "  Generated SSH key: $ssh_key_file"
    echo
    [ "${GENERATE_PASSWORD}" = true ] && (echo "  With password: ${SSH_KEY_PASSWORD}" ; echo)
    echo "  Add the following public key to your Git providers"
    echo
    echo "    $(cat "${ssh_key_file}.pub")"
    echo
    echo "  Git Provider Key Setup"
    echo "    * Github:     https://github.com/settings/keys"
    echo "    * Bitbucket:  https://bitbucket.org/account/settings/ssh-keys/"
    echo "------------------------------------------------------------"
  else
    echo "Something went wrong."
    exit 1
  fi
fi

# Store SSH key password in keyring
if command -v secret-tool &>/dev/null; then
  KEY_ATTRIBUTE="ssh-store:${ssh_key_file}" # Same format used by the Gnome Keyring
  if ! secret-tool lookup unique "$KEY_ATTRIBUTE" &>/dev/null; then
    echo "Storing SSH key in system keyring"
    prompt_for_password SSH_KEY_PASSWORD
    echo "${SSH_KEY_PASSWORD}" | secret-tool store --label="Unlock password for SSH Key: ${SSH_KEY_NAME}_${SSH_KEY_TYPE} (${SSH_KEY_COMMENT})" unique "$KEY_ATTRIBUTE"
  fi
fi

# Add SSH key to SSH agent
PUBLIC_KEY=$(cat "${ssh_key_file}.pub")
if ! ssh-add -L | grep -q "$PUBLIC_KEY"; then
  echo "Adding key to ssh-agent..."
  prompt_for_password
  # Taken from https://unix.stackexchange.com/questions/571741/how-to-pass-a-passphrase-to-ssh-add-without-triggering-a-prompt
  # This echos the password with a slight delay to the underlying ssh-add ask_pass command
  { sleep .2; echo "${SSH_KEY_PASSWORD}"; } | script -q /dev/null -c "ssh-add ${ssh_key_file}"  &>/dev/null
fi
