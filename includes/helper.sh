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
STAGING=0
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
CFG="/hpilo/.${FQDN}.conf"

# Write config file and make it only root accessible
echo "[ilo]" > ${CFG}
echo "login = ${LOGIN}" >> ${CFG}
echo "password = ${PASSWORD}" >> ${CFG}

chmod 700 ${CFG}

#####################################################################
print_msg "FQDN check..."

# Check for DNS resolution
curl https://${FQDN} &> /dev/null
if [ $? = 35 ]; then
  print_err "Problem resolving ${FQDN} to a private IP address. Remedy before continuing."
  exit 1
fi

# Check for HOSTNAME mismatch
CHOSTNAME=$(hpilo_cli -c ${CFG} ${FQDN} get_network_settings | grep "dns_name" | cut -d "'" -f 4)
if [ ${CHOSTNAME} != ${HOSTNAME} ]; then
  print_err "HOSTNAME mismatch between ${CONFIG_NAME} (${HOSTNAME}) and iLO (${CHOSTNAME}). Remedy before continuing."
  exit 1
fi

# Check for DOMAIN mismatch
CDOMAIN=$(hpilo_cli -c ${CFG} ${FQDN} get_network_settings | grep "'domain_name'" | cut -d "'" -f 4)
if [ ${CDOMAIN} != ${DOMAIN} ]; then
  print_err "DOMAIN mismatch between ${CONFIG_NAME} (${DOMAIN}) and iLO (${CDOMAIN}). Remedy before continuing."
  exit 1
fi

# hpilo_cli -c ${CFG} ${FQDN} get_fw_version | grep "firmware_version"

#####################################################################
print_msg "Generating CSR..."

CCSR=$(hpilo_cli -c ${CFG} ${FQDN} certificate_signing_request country= state= locality= organization= organizational_unit= common_name=${FQDN} | grep "BEGIN CERTIFICATE REQUEST")
echo "${CCSR}"
while [ -z "${CCSR}" ]; do
  echo "Sleeping 10 seconds..."
  sleep 10
  CCSR=$(hpilo_cli -c ${CFG} ${FQDN} certificate_signing_request country= state= locality= organization= organizational_unit= common_name=${FQDN} | grep "BEGIN CERTIFICATE REQUEST")
  echo "${CCSR}"
done

CSR="/hpilo/${FQDN}.csr"
hpilo_cli -c ${CFG} ${FQDN} certificate_signing_request country= state= locality= organization= organizational_unit= common_name=${FQDN} > ${CSR}

#####################################################################
print_msg "Creating the import script..."

SCR="/hpilo/${FQDN}.sh"
echo 'CERTFILE="/config/'${FQDN}'/'${FQDN}'.cer"' > ${SCR}
echo 'hpilo_cli -c '${CFG}' '${FQDN}' import_certificate certificate="$(cat $CERTFILE)"' >> ${SCR}
chmod +x ${SCR}

#####################################################################
print_msg "Generating and importing the certificate..."
if [ ${STAGING} -eq 1 ]; then
  ~/.acme.sh/acme.sh --signcsr --csr ${CSR} --dns dns_cf --days 1 --staging --reloadcmd ${SCR}
else
  ~/.acme.sh/acme.sh --signcsr --csr ${CSR} --dns dns_cf --reloadcmd ${SCR}
fi



