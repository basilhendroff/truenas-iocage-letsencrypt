#!/bin/sh
# Build an iocage jail under FreeNAS 11.3-12.0 using the current release of acme.
# git clone https://github.com/basilhendroff/truenas-iocage-acme

# Check for root privileges
if ! [ $(id -u) = 0 ]; then
   echo "This script must be run with root privileges"
   exit 1
fi

#####
#
# General configuration
#
#####

# Initialize defaults
JAIL_IP=""
JAIL_INTERFACES=""
DEFAULT_GW_IP=""
INTERFACE="vnet0"
VNET="on"
POOL_PATH=""
JAIL_NAME="acme"
CONFIG_NAME="acme-config"
POOL_PATH=""
CONFIG_PATH=""

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "${SCRIPT}")

# Check for acme-config and set configuration
if ! [ -e "${SCRIPTPATH}"/"${CONFIG_NAME}" ]; then
  echo "${SCRIPTPATH}/${CONFIG_NAME} must exist."
  exit 1
fi
. "${SCRIPTPATH}"/"${CONFIG_NAME}"

RELEASE=$(freebsd-version | sed "s/STABLE/RELEASE/g" | sed "s/-p[0-9]*//")

#####
#
# Input/Config Sanity checks
#
#####

# Check that necessary variables were set by hpilo-config
if [ -z "${JAIL_IP}" ]; then
  echo 'Configuration error: JAIL_IP must be set'
  exit 1
fi
if [ -z "${JAIL_INTERFACES}" ]; then
  echo 'JAIL_INTERFACES not set, defaulting to: vnet0:bridge0'
  JAIL_INTERFACES="vnet0:bridge0"
fi
if [ -z "${DEFAULT_GW_IP}" ]; then
  echo 'Configuration error: DEFAULT_GW_IP must be set'
  exit 1
fi
if [ -z "${POOL_PATH}" ]; then
  POOL_PATH="/mnt/$(iocage get -p)"
  echo 'POOL_PATH defaulting to '$POOL_PATH
fi
if [ -z "${CONFIG_PATH}" ]; then
  CONFIG_PATH="${POOL_PATH}"/apps/acme/config
fi
if [ "${CONFIG_PATH}" = "${POOL_PATH}" ]
then
  echo "CONFIG_PATH must be different from POOL_PATH!"
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

#####
#
# Jail Creation
#
#####

# List packages to be auto-installed after jail creation
cat <<__EOF__ >/tmp/pkg.json
        {
  "pkgs":[
  "py37-pip","bash","curl","security/ca_root_nss","git-lite"
  ]
}
__EOF__

#  "ca_root_nss","py37-pip","curl","bash","git"

# Create the jail and install previously listed packages
if ! iocage create --name "${JAIL_NAME}" -p /tmp/pkg.json -r "${RELEASE}" interfaces="${JAIL_INTERFACES}" ip4_addr="${INTERFACE}|${JAIL_IP}/24" defaultrouter="${DEFAULT_GW_IP}" boot="on" host_hostname="${JAIL_NAME}" vnet="${VNET}"
then
        echo "Failed to create jail"
        exit 1
fi
rm /tmp/pkg.json

#####
#
# Directory Creation and Mounting
#
#####

mkdir -p "${CONFIG_PATH}"

iocage exec "${JAIL_NAME}" mkdir -p /config

iocage fstab -a "${JAIL_NAME}" "${CONFIG_PATH}" /config nullfs rw 0 0


#####
#
# Python-hpilo Download and Setup
#
#####

#FILE="python-hpilo-4.4.1.tar.gz"
#if ! iocage exec "${JAIL_NAME}" fetch -o /tmp https://files.pythonhosted.org/packages/1f/c8/e4210928e527c44f252ff28b64ee31c4245c449453706cc0784d177081ef/"${FILE}"
#then
#       echo "Failed to download python-hpilo"
#       exit 1
#fi
#if ! iocage exec "${JAIL_NAME}" tar xzf /tmp/"${FILE}" -C /bin/
#then
#       echo "Failed to extract python-hpilo"
#       exit 1
#fi
#iocage exec "${JAIL_NAME}" rm /tmp/"${FILE}"

iocage exec "${JAIL_NAME}" pip download --dest /tmp python-hpilo
iocage exec "${JAIL_NAME}" pip install --src /tmp python-hpilo

#iocage exec "${JAIL_NAME}" pip install /tmp/"${FILE}"
iocage exec "${JAIL_NAME}" sed -i '' 's|"RC4-SHA:" + ||' /usr/local/lib/python3.7/site-packages/hpilo.py

#iocage exec "${JAIL_NAME}" "curl https://get.acme.sh | sh"
iocage exec "${JAIL_NAME}" "git clone https://github.com/Neilpang/acme.sh.git"
iocage exec "${JAIL_NAME}" "cd /acme.sh && ./acme.sh --install --config-home /config"
iocage exec "${JAIL_NAME}" sed -i '' "s|md5sum|md5|g" ~/.acme.sh/deploy/fritzbox.sh

iocage restart "${JAIL_NAME}"
