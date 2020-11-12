#!/usr/bin/env bash
#
# Call this script with as only argument a OVPN File.
# This script expects the two following files:
#
# ./vpn.conf
# File containing the openvpn configurations.
# A default file will be created if one is missing.
#
# ./auth.conf
# The authentication file with the username and password for the VPN provider

# Current path of the script
SCRIPTPATH="$(dirname "$(realpath $0)")"

VPN_CONFIG="${SCRIPTPATH}/vpn.conf"
VPN_AUTH="${SCRIPTPATH}/auth.conf"
VPN_OVPN="${1}"

# ovpn argument
if [ -z "$VPN_OVPN" ]; then
    echo "No OVPN file supplied"
    exit 1
fi

# Check VPN config file
if [ ! -f "${VPN_CONFIG}" ]; then
    echo "No VPN config file found (${VPN_CONFIG})"
    echo "Creating VPN config file"
    echo "auth-user-pass ${VPN_AUTH}" > "${VPN_CONFIG}"
fi

# Check VPN auth file
if [ ! -f "${VPN_AUTH}" ]; then
    echo "No auth.conf found (${VPN_AUTH})"
    echo
    echo "Example file output:"
    echo "$ cat ./auth.conf"
    echo "<username>"
    echo "<password>"
    exit 1
fi

# Connect to VPN
sudo openvpn --config "${VPN_OVPN}" --config "${VPN_CONFIG}"
