#!/usr/bin/env bash
#
# Utility script to get pgp subkey key details matching certain criteria. See print_usage for more detail.

: ${KEY_CREATED_AFTER:="0"}
: ${KEY_FINGERPRINT:=""}
: ${PRINT_DETAIL:="key-id"}

print_usage() {
  echo "Usage: ${0} [OPTIONS]"
  echo
  echo "Utility script to find and retrieve specific PGP subkey details on this device"
  echo "using the primary fingerprint. This can be useful for:"
  echo "  - Installing or provisioning GPG subkeys when no matching subkey is found."
  echo "  - Assisting with configuring '.gitconfig' by determining the correct 'user.signingkey' value."
  echo
  echo "Required options:"
  echo "  -f, --fingerprint=FINGERPRINT   primary key fingerprint."
  echo
  echo "Optional options:"
  echo "  -a, --after=EPOCH               only search keys created after EPOCH date. (default: '${KEY_CREATED_AFTER}')"
  echo "  -d, --detail=DETAIL              What detail to print (default: '${PRINT_DETAIL}'), valid values are:"
  echo "                                    * key-id      : Key ID"
  echo "                                    * fingerprint : Key fingerprint"
  echo "                                    * expiration  : Key expiration date"
  echo "                                    * key-grip    : Key grip"
  echo "  -h, --help                      print help"
  echo
  echo "ENVIRONMENT VARIABLES:"
  echo "  KEY_CREATED_AFTER only search keys created after EPOCH date (default: '${KEY_CREATED_AFTER}')"
  echo "  KEY_FINGERPRINT   primary key fingerprint"
  echo "  PRINT_DETAIL      What detail to print. See --detail (-d) for valid values (default: '${PRINT_DETAIL}')"
  echo
  echo "EXAMPLES:"
  echo "  \$ ${0} -f 40157412895F2634C4409E77C36EC45D885B9E3F --detail=fingerprint"
  echo "  AD4300548ABB76DAA265603188D319A165F9A092"
  echo
  echo "  \$ ${0} -f 40157412895F2634C4409E77C36EC45D885B9E3F --detail=key-id"
  echo "  88D319A165F9A092"
}

while getopts 'a:d:f:h-:' OPT; do  # Make sure to keep the last '-:' as this is for long options
  # support long options: https://stackoverflow.com/a/28466267/519360
  if [ "${OPT}" = "-" ]; then   # long option: reformulate OPT and OPTARG
    OPT="${OPTARG%%=*}"       # extract long option name
    OPTARG="${OPTARG#"${OPT}"}" # extract long option argument (may be empty)
    OPTARG="${OPTARG#=}"      # if long option argument, remove assigning `=`
  fi
  case "${OPT}" in
    a | after         ) KEY_CREATED_AFTER="${OPTARG}" ;;
    d | detail        ) PRINT_DETAIL="${OPTARG}" ;;
    f | fingerprint   ) KEY_FINGERPRINT="${OPTARG}" ;;
    h | help          ) print_usage; exit 0 ;;
    \?                ) exit 2 ;; # bad short option (error reported via getopts)
    *                 ) echo "Illegal option --${OPT}" ;; # bad long option
  esac
done

if [[ -z "${KEY_FINGERPRINT}" ]]; then
  echo "Error: --fingerprint (-f) option is required and cannot be empty." >&2
  echo ""
  print_usage
  exit 1
fi

# The purpose of this command is to extract information about a PGP subkey that meets specific criteria.
# We need to determine:
#   1. The subkey ID
#   2. The subkey fingerprint
#   3. The subkey expiration time
#
# GPG outputs data in a structured format using "--with-colons", where each line starts with a record type, see example:
# (e.g., "pub" for the primary key, "sub" for subkeys, "fpr" for fingerprints, etc.).
# For output format see:
# - https://git.gnupg.org/cgi-bin/gitweb.cgi?p=gnupg.git;a=blob;f=doc/DETAILS;h=470497dcd7bf87011d136a2be36fac86dcfe5cda;hb=HEAD
# - or: https://github.com/gpg/gnupg/blob/master/doc/DETAILS
# $ gpg --with-colons \
#     --list-keys \
#     --with-secret  \
#     --with-fingerprint \
#     --with-fingerprint 40157412895F2634C4409E77C36EC45D885B9E3F
#   tru::1:1739399476:0:3:1:5
#   pub:-:255:22:C36EC45D885B9E3F:1739364748:::-:::scESCA:::+::ed25519:::0:
#   fpr:::::::::40157412895F2634C4409E77C36EC45D885B9E3F:
#   grp:::::::::4852AD98E8B5E55AD59AA622AB683FF2AAF054F4:
#   uid:-::::1739364748::2F161AA2CFDD2B76DC56608E073E02F41609D5A3::Ingmar Test Key <test@dels.ink>::::::::::0:
#   sub:-:255:18:5BF7762281E3E5EF:1739364748::::::e:::+::cv25519::
#   fpr:::::::::E476E52F02B18298538A84E85BF7762281E3E5EF:
#   grp:::::::::A8123DFC9E10DB64340AB0047B236413E6869F7B:
#   sub:-:255:22:88D319A165F9A092:1739404327:1770940327:::::sa:::+::ed25519::
#   fpr:::::::::AD4300548ABB76DAA265603188D319A165F9A092:
#   grp:::::::::3D0E9DED4C8069B33CED6771FE418B2CCFD2DB1D:
#
# We need to parse multiple rows and output when we have all the data we need:
#   - The "sub" (subkey) records contain metadata such as the key ID, creation time, and capabilities.
#   - The "fpr" (fingerprint) records provide the actual fingerprint but appear **separately** from the "sub" records.
#     - We must **correlate** fingerprint records with their respective subkey records, as they are not on the same line.
#   - The "grp" (keygrip) records provide the keygrip for that specific key but appears **separately** from the "sub" records.
#
# The process works as follows:
# 1. **Parse the "sub" record**:
#    - Extract key ID, creation time, expiration time, key capabilities, and secret key availability.
# 2. **Parse the "fpr" record**:
#    - Extract the key fingerprint and ensure it corresponds to a subkey we just processed.
#    - Apply filtering conditions to select a suitable key:
#       - Must have been created after a certain date. (defaults to 0)
#       - Must have an expiration time.
#       - Must have both signing ('s') and authentication ('a') capabilities.
#       - Must have an associated secret key.
# 3. **Parse the "grp" record**
# If a key meets all these conditions, we output its details, which are captured by the `read` command.
read -r SUBKEY_ID SUBKEY_FINGERPRINT SUBKEY_EXPIRATION_TIME SUBKEY_KEYGRIP < <(
  gpg --with-colons \
    --list-keys \
    --with-secret  \
    --with-fingerprint \
    --with-fingerprint \
    "${KEY_FINGERPRINT}" 2> /dev/null | \
    awk -F: --assign created_after="${KEY_CREATED_AFTER}" '
      {
        record_type = $1  # Field 1 - Type of record (e.g., "sub - Subkey (secondary key)")
        # First sub types appear, get all required information
        if (record_type == "sub") {
          key_id        = $5  # Field 5 - Key ID
          creation      = $6  # Field 6 - Creation date
          expiration    = $7  # Field 7 - Expiration date (empty means no expiration)
          capabilities  = $12 # Field 12 - Key capabilities (e.g., "esa" Encrypt(e), Sign(s), Certify(c), Authentication(a), Unknown capability(?))
          serial_number = $15 # Field 15 - If option –with-secret provided "x" will indicate secret availability - Used in sec/ssb to print the serial number of a token
          sub_found     = 1
        }

        # After sub, fpr (fingerprint) records appear.
        if (record_type == "fpr") {
          key_fingerprint = $10  # Field 10 - User-ID A FPR record stores the fingerprint here.

          # Only when these conditions are met, will we print the data
          can_sign_and_auth = (capabilities ~ /s/ && capabilities ~ /a/)
          has_expiration = (expiration != "")
          has_secret = (serial_number == "+")
          is_created_after = (creation > created_after)
          is_fingerprint_of_subkey = (key_fingerprint ~ key_id )

          if (is_created_after && is_fingerprint_of_subkey && has_expiration && has_secret && can_sign_and_auth) {
            fpr_found = 1
          }
        }

        # After fpr, grp (keygrip) records appear.
        if (record_type == "grp" && sub_found && fpr_found) {
          key_keygrip = $10  # Field 10 - User-ID/keygrip A GRP records puts the keygrip here
          grp_found   = 1
        }

        # When all records are processed, we can print all the details
        if (sub_found && fpr_found && grp_found) {
          sub_found = 0
          fpr_found = 0
          grp_found = 0
          print \
            key_id, \
            key_fingerprint, \
            expiration, \
            key_keygrip
        }
      }
    '
)

case "${PRINT_DETAIL}" in
  key-id      ) echo "${SUBKEY_ID}" ;;
  fingerprint ) echo "${SUBKEY_FINGERPRINT}" ;;
  expiration  ) echo "${SUBKEY_EXPIRATION_TIME}" ;;
  key-grip    ) echo "${SUBKEY_KEYGRIP}" ;;
  *           ) echo "Detail option ${PRINT_DETAIL} not supported" ;;
esac
