#!/bin/bash
# iLO configuration and setup

print_msg () {
  echo
  echo -e "\e[1;32m"$1"\e[0m"
  echo
}

print_err () {
  echo -e "\e[1;31m"$1"\e[0m"
  echo
}

# Check for root privileges
if ! [ $(id -u) = 0 ]; then
   print_err "This script must be run with root privileges"
   exit 1
fi

#####################################################################
print_msg "General configuration..."

# Initialize defaults
HOSTNAME=""
DOMAIN=""
LOGIN=""
PASSWORD=""
CONFIG_NAME="helper.cfg"

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "${SCRIPT}")

# Check for helper.cfg and set configuration
if ! [ -e "${SCRIPTPATH}"/"${CONFIG_NAME}" ]; then
  print_err "${SCRIPTPATH}/${CONFIG_NAME} must exist."
  exit 1
fi
chmod 700 "${SCRIPTPATH}"/"${CONFIG_NAME}"
. "${SCRIPTPATH}"/"${CONFIG_NAME}"

#####################################################################
print_msg "Input/Config Sanity checks..."

# Check that necessary variables were set by helper.cfg
if [ -z "${HOSTNAME}" ]; then
  print_err 'Configuration error: HOSTNAME must be set'
  exit 1
fi
if [ -z "${DOMAIN}" ]; then
  print_err 'Configuration error: DOMAIN must be set'
  exit 1
fi
if [ -z "${LOGIN}" ]; then
  print_err 'Configuration error: LOGIN must be set'
  exit 1
fi
if [ -z "${PASSWORD}" ]; then
  print_err 'Configuration error: PASSWORD must be set'
  exit 1
fi

#####################################################################
print_msg "Writing HPILO config file..."

FQDN="${HOSTNAME}.${DOMAIN}"
CFG=".${FQDN}.conf"
echo "[ilo]" > ${CFG}
echo "login = ${LOGIN}" >> ${CFG}
echo "password = ${PASSWORD}" >> ${CFG}

chmod 700 ${CFG}

print_msg "Check parameters..."

hpilo_cli -c ${CFG} ${FQDN} get_uid_status