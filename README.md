# truenas-iocage-letsencrypt
This script builds a Let's Encrypt server in a TrueNAS jail. It will create a jail, install the latest version of acme.sh, a Let's Encrypt client, and several deployment tools, and store certificates and other data files outside the jail, so they will not be lost in the event you need to rebuild the jail.  

## Status
This script will work with FreeNAS 11.3, and TrueNAS CORE 12 or later. Due to the EOL status of FreeBSD 11.2, it is unlikely to work reliably with earlier releases of FreeNAS.

## Usage

An acme.sh server and a collection of utilities for issuing and renewing Let's Encrypt certificates for a variety of devices and servers on the local network including:
1. [FRITZ!Box](https://github.com/basilhendroff/truenas-iocage-letsencrypt/blob/main/includes/FRITZ!BOX.md) - Only tested on a FRITZ!Box 7490, but this should work for the majority of non-legacy FRITZ!Box models.
2. [HP iLO](https://github.com/basilhendroff/truenas-iocage-letsencrypt/blob/main/includes/HPILO.md) - Only tested on iLO 4 on HP Gen8 microservers, but this should work for all RILOE II/iLO versions up to and including iLO 4.
3. [FreeNAS/TrueNAS](https://github.com/basilhendroff/truenas-iocage-letsencrypt/blob/truenas/includes/TRUENAS.md) - Tested on FreeNAS 11.3 and TrueNAS 12.0, but this should work for all versions from 11.1.

Once you've confirmed the installation of the acme.sh server, click on any of the above hyperlinks of interest for detailed deployment instructions.

### Prerequisites (DNS API)

Your DNS provider must support API access, and acme.sh must support your DNS provider.

https://github.com/acmesh-official/acme.sh/wiki/dnsapi

### Prerequisites (Other)

Although not required, it's recommended to create a Dataset named `apps` with a sub-dataset named `letsencrypt` on your main storage pool.  Many other jail guides also store their configuration and data in subdirectories of `pool/apps/` If this dataset is not present, directory `/apps/letsencrypt` will be created in `$POOL_PATH`.

### Installation

Download the repository to a convenient directory on your TrueNAS system by changing to that directory and running `git clone https://github.com/basilhendroff/truenas-iocage-letsencrypt`. Then change into the new `truenas-iocage-letsencrypt` directory and create a file called `le-config` with your favorite text editor. In its minimal form, it would look like this:

```
JAIL_IP="10.1.1.3"
DEFAULT_GW_IP="10.1.1.1"
```

Many of the options are self-explanatory, and all should be adjusted to suit your needs, but only a few are mandatory. The mandatory options are:

- JAIL_IP: The IP address for your jail. You can optionally add the netmask in CIDR notation (e.g., 192.168.1.199/24). If not specified, the netmask defaults to 24 bits. Values of less than 8 bits or more than 30 bits are invalid.
- DEFAULT_GW_IP: The address for your default gateway.

In addition, there are some other options which have sensible defaults, but can be adjusted if needed. These are:

- JAIL_NAME: The name of the jail, defaults to `letsencrypt`.
- POOL_PATH: The path for your data pool. It is set automatically if left blank.
- LE_PATH: Data files are stored in this path; defaults to `$POOL_PATH/apps/letsencrypt`.
- INTERFACE: The network interface to use for the jail. Defaults to `vnet0`.
- VNET: Whether to use the iocage virtual network stack. Defaults to `on`.


### Execution

Once you've downloaded the script and prepared the configuration file, run this script (`script letsencrypt.log ./le-jail.sh`). The script will run for several minutes. When it finishes, your jail will be created and acme.sh along with several deployment tools will be installed.

### Test

To check your installation, enter your Let's Encrypt jail `iocage console letsencrypt` and check the version of the installed kit.

```
# acme.sh --version
https://github.com/acmesh-official/acme.sh
v2.8.8
# hpilo_cli -version
4.4.1
# pip --version
pip 20.2.3 from /usr/local/lib/python3.7/site-packages/pip (python 3.7)
# python3 --version
Python 3.7.9
```

## Support and Discussion

Support channels:
1. [acme.sh](https://github.com/acmesh-official/acme.sh)
2. [python-hpilo](https://github.com/seveas/python-hpilo)
3. [Let's Encrypt Community Forum](https://community.letsencrypt.org/)
4. [Let's Encrypt with FreeNAS 11.1 and later](https://www.truenas.com/community/resources/lets-encrypt-with-freenas-11-1-and-later.82/)

Questions or issues about this resource can be raised in [this forum thread](). You may also find this [Q & A](https://github.com/basilhendroff/truenas-iocage-letsencrypt/blob/main/includes/Q&A.md) useful.

### To Do
Apart from supporting the FRITZ!Box, acme.sh comes with a whole bunch of [deploy hooks](https://github.com/acmesh-official/acme.sh/wiki/deployhooks) for other devices and servers. However, as I can't test these, I unable to confirm they will work without modification on FreeBSD and FreeBSD embedded systems like FreeNAS. As it is, I've had to tweak the HP iLO python script to make this work on FreeNAS. [Until recently](https://community.letsencrypt.org/t/can-acme-sh-deploy-certs-to-more-than-one-fritz-box-router/137854/9?u=basilhendroff), I've had to do the same with the FRITZ!box deployment hook. If there is a hook that's of interest, try it. If it works, let others know in the discussion area for this resource. If you can make it work with a minor tweak, submit a pull request [here](https://github.com/basilhendroff/truenas-iocage-letsencrypt) and I'll consider including it in this resource.

## Disclaimer
It's your data. It's your responsibility. This resource is provided as a community service. Use it at your own risk.
