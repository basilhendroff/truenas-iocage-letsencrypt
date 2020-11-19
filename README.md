# A Work in Progress
# truenas-iocage-letsencrypt
This script builds a Let's Encrypt server in a TrueNAS jail. It will create a jail, install the latest version of acme.sh and several deploment tools, and store data files outside the jail, so it will not be lost in the event you need to rebuild the jail.  

## Status
This script will work with FreeNAS 11.3, and TrueNAS CORE 12 or later. Due to the EOL status of FreeBSD 11.2, it is unlikely to work reliably with earlier releases of FreeNAS.

## Usage
An acme.sh server including a collection of utilities for issuing and renewing Let's Encrypt certificates for devices on the local network including:
1. [FRITZ!Box]() (Only tested on a FRITZ!Box 7490, but should work for the majority of non-legacy FRITZ!Box models).
2. [HP iLO]() (Only tested on a iLO 4 on a HP Gen8 microserver, but should work for all RILOE II/iLO versions up to and including iLO 4).

Once you've confirmed the installation of the server, click on any of the hyperlinks of interest above for detailed deployment instructions.

### Prerequisites (DNS API)

Your DNS provider must support API access, and acme.sh must support your DNS provider.

https://github.com/acmesh-official/acme.sh/wiki/dnsapi

Cloudflare is the default DNS provider for this resource, but this can be easily configured to any of the supported providers. 

### Prerequisites (Other)

Although not required, it's recommended to create a Dataset named `apps` with a sub-dataset named `letsencrypt` on your main storage pool.  Many other jail guides also store their configuration and data in subdirectories of `pool/apps/` If this dataset is not present, directory `/apps/letsencrypt` will be created in `$POOL_PATH`.

### Installation

Download the repository to a convenient directory on your TrueNAS system by changing to that directory and running `git clone https://github.com/basilhendroff/truenas-iocage-letsencrypt`. Then change into the new truenas-iocage-tautulli directory and create a file called `le-config` with your favorite text editor. In its minimal form, it would look like this:

```
JAIL_IP="10.1.1.3"
DEFAULT_GW_IP="10.1.1.1"
```

Many of the options are self-explanatory, and all should be adjusted to suit your needs, but only a few are mandatory. The mandatory options are:

- JAIL_IP is the IP address for your jail. You can optionally add the netmask in CIDR notation (e.g., 192.168.1.199/24). If not specified, the netmask defaults to 24 bits. Values of less than 8 bits or more than 30 bits are invalid.
- DEFAULT_GW_IP is the address for your default gateway

In addition, there are some other options which have sensible defaults, but can be adjusted if needed. These are:

- JAIL_NAME: The name of the jail, defaults to `letsencrypt`.
- POOL_PATH: The path for your data pool. It is set automatically if left blank.
- DATA_PATH: Data files are stored in this path; defaults to `$POOL_PATH/apps/letsencrypt`.
- INTERFACE: The network interface to use for the jail. Defaults to `vnet0`.
- VNET: Whether to use the iocage virtual network stack. Defaults to `on`.

### Execution

Once you've downloaded the script and prepared the configuration file, run this script (`./le-jail.sh`). The script will run for several minutes. When it finishes, your jail will be created and acme.sh along with several deployment tools will be installed.

### Test

To check your installation, enter your `letsencrypt` jail `iocage console letsencrypt` and check the version of the installed kit.

```
# acme.sh --version
https://github.com/acmesh-official/acme.sh
v2.8.8
# hpilo_cli -version
4.4.1
# pip --version
pip 20.2.3 from /usr/local/lib/python3.7/site-packages/pip (python 3.7)
```

## Support and Discussion

Support channels:
1. [acme.sh](https://github.com/acmesh-official/acme.sh)
2. [python-hpilo](https://github.com/seveas/python-hpilo)
3. [Let's Encrypt Community Forum](https://community.letsencrypt.org/)

Questions or issues about this resource can be raised in [this forum thread]().  

### To Do
Apart from supporting the FRITZ!Box, acme.sh comes with a whole bunch of [deployment hooks](https://github.com/acmesh-official/acme.sh/wiki/deployhooks) for other devices and servers. However, they have not been tested on FreeBSD and FreeBSD embedded systems like FreeNAS. As it is, I've had to tweak the FRITZ!box deployment hook to make it work on FreeNAS. If there is a hook that's of interest, try it. If it works, let others know in the discussion area for this resource. If you can make it work with a minor tweak, submit a pull request [here](https://github.com/basilhendroff/truenas-iocage-letsencrypt) and I'll include it in this resource.

## Disclaimer
It's your data. It's your responsibility. This resource is provided as a community service. Use it at your own risk.
