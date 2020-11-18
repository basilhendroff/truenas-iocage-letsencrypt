#!/bin/sh
# Build an iocage jail under FreeNAS 11.3-12.0 using the current release of acme.sh
# git clone https://github.com/basilhendroff/truenas-iocage-letsencrypt

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
JAIL_IP=""
JAIL_INTERFACES=""
DEFAULT_GW_IP=""
INTERFACE="vnet0"
VNET="on"
POOL_PATH=""
JAIL_NAME="letsencrypt"
CONFIG_NAME="le-config"
POOL_PATH=""
CONFIG_PATH=""
HPILO_PATH=""
CERT_EMAIL=""

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "${SCRIPT}")

# Check for le-config and set configuration
if ! [ -e "${SCRIPTPATH}"/"${CONFIG_NAME}" ]; then
  print_err "${SCRIPTPATH}/${CONFIG_NAME} must exist."
  exit 1
fi
. "${SCRIPTPATH}"/"${CONFIG_NAME}"
INCLUDES_PATH="${SCRIPTPATH}"/includes

RELEASE=$(freebsd-version | sed "s/STABLE/RELEASE/g" | sed "s/-p[0-9]*//")

#####################################################################
print_msg "Input/Config Sanity checks..."

# Check that necessary variables were set by hpilo-config
if [ -z "${JAIL_IP}" ]; then
  print_err 'Configuration error: JAIL_IP must be set'
  exit 1
fi
if [ -z "${JAIL_INTERFACES}" ]; then
  print_msg 'JAIL_INTERFACES not set, defaulting to: vnet0:bridge0'
  JAIL_INTERFACES="vnet0:bridge0"
fi
if [ -z "${DEFAULT_GW_IP}" ]; then
  print_err 'Configuration error: DEFAULT_GW_IP must be set'
  exit 1
fi
if [ -z "${CERT_EMAIL}" ]; then
  print_err 'Configuration error: CERT_EMAIL must be set'
  exit 1
fi
if [ -z "${POOL_PATH}" ]; then
  POOL_PATH="/mnt/$(iocage get -p)"
  print_msg 'POOL_PATH defaulting to '$POOL_PATH
fi
if [ -z "${CONFIG_PATH}" ]; then
  CONFIG_PATH="${POOL_PATH}"/apps/letsencrypt/config
fi
if [ -z "${HPILO_PATH}" ]; then
  HPILO_PATH="${POOL_PATH}"/apps/letsencrypt/hpilo
fi
if [ "${CONFIG_PATH}" = "${HPILO_PATH}" ]
then
  print_err "CONFIG_PATH and HPILO_PATH cannot be the same!"
  exit 1
fi
if [ "${CONFIG_PATH}" = "${POOL_PATH}" ] || [ "${HPILO_PATH}" = "${POOL_PATH}" ]
then
  print_err "CONFIG_PATH and HPILO_PATH must be different from POOL_PATH!"
  exit 1
fi

# Extract IP and netmask, sanity check netmask
IP=$(echo ${JAIL_IP} | cut -f1 -d/)
NETMASK=$(echo ${JAIL_IP} | cut -f2 -d/)
if [ "${NETMASK}" = "${IP}" ]
then
  NETMASK="24"
fi
if [ "${NETMASK}" -lt 8 ] || [ "${NETMASK}" -gt 30 ]
then
  NETMASK="24"
fi

#####################################################################
print_msg "Jail Creation. Installing packages will take a while..."

# List packages to be auto-installed after jail creation
cat <<__EOF__ >/tmp/pkg.json
        {
  "pkgs":[
  "py37-pip","bash","curl","security/ca_root_nss","git-lite"
  ]
}
__EOF__

# Create the jail and install previously listed packages
if ! iocage create --name "${JAIL_NAME}" -p /tmp/pkg.json -r "${RELEASE}" interfaces="${JAIL_INTERFACES}" ip4_addr="${INTERFACE}|${JAIL_IP}/24" defaultrouter="${DEFAULT_GW_IP}" boot="on" host_hostname="${JAIL_NAME}" vnet="${VNET}"
then
        print_err "Failed to create jail"
        exit 1
fi
rm /tmp/pkg.json

#####################################################################
print_msg "Directory Creation and Mounting..."

mkdir -p "${CONFIG_PATH}"
chmod 770 "${CONFIG_PATH}"
iocage exec "${JAIL_NAME}" mkdir -p /config
iocage fstab -a "${JAIL_NAME}" "${CONFIG_PATH}" /config nullfs rw 0 0

mkdir -p "${HPILO_PATH}"
chmod 770 "${HPILO_PATH}"
iocage exec "${JAIL_NAME}" mkdir -p /hpilo
iocage fstab -a "${JAIL_NAME}" "${HPILO_PATH}" /hpilo nullfs rw 0 0

iocage exec "${JAIL_NAME}" mkdir -p /tmp/includes
iocage fstab -a "${JAIL_NAME}" "${INCLUDES_PATH}" /tmp/includes nullfs rw 0 0

#####################################################################
print_msg "acme.sh download and setup..."

iocage exec "${JAIL_NAME}" "cd /tmp && git clone https://github.com/Neilpang/acme.sh.git"
iocage exec "${JAIL_NAME}" "cd /tmp/acme.sh && ./acme.sh --install --config-home /config --accountemail ${CERT_EMAIL}"
iocage exec "${JAIL_NAME}" sed -i '' "s|md5sum|md5|g" ~/.acme.sh/deploy/fritzbox.sh

#####################################################################
print_msg "python-hpilo download and setup..."

iocage exec "${JAIL_NAME}" pip download --dest /tmp python-hpilo
iocage exec "${JAIL_NAME}" pip install --src /tmp python-hpilo

iocage exec "${JAIL_NAME}" sed -i '' 's|"RC4-SHA:" + ||' /usr/local/lib/python3.7/site-packages/hpilo.py

iocage exec "${JAIL_NAME}" cp /tmp/includes/hpilo.sh /hpilo
#iocage exec "${JAIL_NAME}" cp /tmp/includes/hpilo.cfg /hpilo

#####################################################################
print_msg "Cleanup..."

iocage restart "${JAIL_NAME}"
