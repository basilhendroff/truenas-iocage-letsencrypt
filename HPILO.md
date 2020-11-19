# HP iLO Deployment
1. Enter the Let's Encrypt jail `iocage console letsencrypt` and change to the hpilo working directory `cd /hpilo`.
2. Create a file called `hpilo.cfg` with your favorite text editor. In its minimal form, it would look something like this:
```
USERNAME="Administrator"
PASSWORD="alakazam"
HOSTNAME="ilo"
DOMAIN="mydomain.com"
```
The mandatory options are:
- USERNAME: Username of the iLO administrator.
- PASSWORD: The iLO administrator password.
- HOSTNAME: The iLO hostname.
- DOMAIN:   Your registered domain name.

Options with defaults:
- STAGING:  While finding your way around this resource, set STAGING to 1 to avoid hitting Let's Encrypt rate limits. The default is 0.
- DNSAPI:   A supported DNS provider for automaitc DNS API integration https://github.com/acmesh-official/acme.sh/wiki/dnsapi.
