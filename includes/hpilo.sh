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
USERNAME=""
PASSWORD=""
STAGING=0
DNSAPI="dns_cf"
CONFIG_NAME="hpilo.cfg"

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "${SCRIPT}")

# Check for helper.cfg and set configuration
if ! [ -e "${SCRIPTPATH}"/"${CONFIG_NAME}" ]; then
  print_err "${SCRIPTPATH}/${CONFIG_NAME} must exist."
  exit 1
fi

# Make the file root readable as it contains passwords
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
if [ -z "${USERNAME}" ]; then
  print_err 'Configuration error: USERNAME must be set'
  exit 1
fi
if [ -z "${PASSWORD}" ]; then
  print_err 'Configuration error: PASSWORD must be set'
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
print_msg "Writing HPILO config file..."

CFG="/hpilo/.${FQDN}.conf"

# Write config file and make it only root accessible
echo "[ilo]" > ${CFG}
echo "login = ${USERNAME}" >> ${CFG}
echo "password = ${PASSWORD}" >> ${CFG}

# Make the file root readable as it contains passwords
chmod 700 ${CFG}

#####################################################################
print_msg "Credentials validation..."

hpilo_cli -c ${CFG} ${FQDN} get_fw_version
if [ $? -ne 0 ]; then
  print_err "Invalid login credentials. Remedy before continuing."
  exit 1
fi

#####################################################################
print_msg "HOSTNAME and DOMAIN validation..."

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

#####################################################################
print_msg "Generating CSR..."

CCSR=$(hpilo_cli -c ${CFG} ${FQDN} certificate_signing_request country= state= locality= organization= organizational_unit= common_name=${FQDN} | grep "BEGIN CERTIFICATE REQUEST")
echo "${CCSR}"
TIMER=30
while [ -z "${CCSR}" ]; do
  echo "Sleeping ${TIMER} seconds..."
  sleep ${TIMER}
  CCSR=$(hpilo_cli -c ${CFG} ${FQDN} certificate_signing_request country= state= locality= organization= organizational_unit= common_name=${FQDN} | grep "BEGIN CERTIFICATE REQUEST")
  echo "${CCSR}"
done

CSR="/hpilo/${FQDN}.csr"
hpilo_cli -c ${CFG} ${FQDN} certificate_signing_request country= state= locality= organization= organizational_unit= common_name=${FQDN} > ${CSR}

#####################################################################
print_msg "Creating the import script..."

SCRIPT="/hpilo/${FQDN}.sh"
echo 'CERTFILE="/config/'${FQDN}'/'${FQDN}'.cer"' > ${SCRIPT}
echo 'hpilo_cli -c '${CFG}' '${FQDN}' import_certificate certificate="$(cat $CERTFILE)"' >> ${SCRIPT}
chmod +x ${SCRIPT}

#####################################################################
print_msg "Generating and importing the certificate..."
if [ ${STAGING} -eq 0 ]; then
  ~/.acme.sh/acme.sh --signcsr --csr ${CSR} --dns ${DNSAPI} --reloadcmd ${SCRIPT} --force
else
  ~/.acme.sh/acme.sh --signcsr --csr ${CSR} --dns ${DNSAPI} --days 1 --staging --reloadcmd ${SCRIPT} --force
fi
