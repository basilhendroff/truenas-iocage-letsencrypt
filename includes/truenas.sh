#!/bin/bash
# FreeNAS/TrueNAS helper script

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
#USERNAME=""
PASSWORD=""
API_KEY=""
STAGING=0
DNSAPI="dns_cf"
CONFIG_NAME="truenas.cfg"

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "${SCRIPT}")

# Check for hpilo.cfg and set configuration
if ! [ -e "${SCRIPTPATH}"/"${CONFIG_NAME}" ]; then
  print_err "${SCRIPTPATH}/${CONFIG_NAME} must exist."
  exit 1
fi

# Make the file root readable only as it contains passwords
chmod 700 "${SCRIPTPATH}"/"${CONFIG_NAME}"

. "${SCRIPTPATH}"/"${CONFIG_NAME}"

#####################################################################
print_msg "Input/Config Sanity checks..."

# Check that necessary variables were set by hpilo.cfg
if [ -z "${HOSTNAME}" ]; then
  print_err 'Configuration error: HOSTNAME must be set'
  exit 1
fi
if [ -z "${DOMAIN}" ]; then
  print_err 'Configuration error: DOMAIN must be set'
  exit 1
fi
#if [ -z "${USERNAME}" ]; then
#  print_err 'Configuration error: USERNAME must be set'
#  exit 1
#fi
if [ -z "${PASSWORD}" ] && [ -z "${API_KEY}" ]; then
  print_err 'Configuration error: PASSWORD or API_KEY must be set'
  exit 1
fi
if [ -n "${PASSWORD}" ] && [ -n "${API_KEY}" ]; then
  print_err 'Configuration error: Either PASSWORD or API_KEY must be set, not both.'
  exit 1
fi

#####################################################################
print_msg "DNS resolver check..."

FQDN="${HOSTNAME}.${DOMAIN}"

# Check for DNS resolution
curl https://${FQDN} 
CHK=$?
if [ ${CHK} -ne 60 ] && [ ${CHK} -ne 0 ]; then
  print_err "Problem resolving ${FQDN} to a private IP address. Remedy before continuing."
  exit 1
fi
#####################################################################
print_msg "Writing TrueNAS/FreeNAS config file..."

CFG="/truenas/${FQDN}"

# Write config file and make it only root accessible
echo "[deploy]" > ${CFG}
echo "login = ${USERNAME}" >> ${CFG}
if [ -n "${PASSWORD}" ]; then
  echo "password = ${PASSWORD}" >> ${CFG}
fi
if [ -n "${API_KEY}" ]; then
  echo "api_key = ${API_KEY}" >> ${CFG}
fi
echo "connect_host = ${FQDN}" >> ${CFG}

# Make the file root readable as it contains passwords
chmod 700 ${CFG}

#####################################################################
exit 1
print_msg "Generating and importing the certificate..."
SCRIPT="/root/deploy_freenas.py" 
if [ ${STAGING} -eq 0 ]; then
  ~/.acme.sh/acme.sh --issue -d ${FQDN} --dns ${DNSAPI} --reloadcmd ${SCRIPT} --config ${CFG} --force
else
  ~/.acme.sh/acme.sh --issue -d ${FQDN} --dns ${DNSAPI} --days 1 --staging --reloadcmd ${SCRIPT} --config ${CFG} --force
fi
