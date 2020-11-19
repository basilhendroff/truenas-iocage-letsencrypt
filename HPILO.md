# Let's Encrypt HP iLO 
Before commencing, ensure your iLOs are updated with the latest firmware (iLO UI > Administration > Firmware) and the hostname and domain fields (iLO UI > Network > iLO Dedicated Network Port > General) are configured for each iLO.

1. Configure your DNS resolver to resolve the iLO FQDN to the IP address of the iLO. For example, `ilo.mydomain.com` must resolve to the iLO IP on the internal network.
2. Enter the Let's Encrypt jail `iocage console letsencrypt` and change to the hpilo working directory `cd /hpilo`.
3. Edit the file called `hpilo.cfg` with your favorite text editor. In its minimal form, it would look something like this:
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

Other options with defaults include:
- STAGING:  While finding your way around this resource, you're encouraged to set STAGING to 1 to avoid hitting Let's Encrypt rate limits. The default is 0.
- DNSAPI:   A supported DNS provider for automatic DNS API integration https://github.com/acmesh-official/acme.sh/wiki/dnsapi. The default is `dns_cf` (Cloudflare).
4. If this is your first deployment, continue with this step, otherwise, skip to the next step. Set up the API credentials for your DNS provider https://github.com/acmesh-official/acme.sh/wiki/dnsapi. For example, for Cloudflare:
```
setenv CF_Token "sdfsdfsdfljlbjkljlkjsdfoiwje"
setenv CF_Account_ID "xxxxxxxxxxxxx"
```
SIDE NOTE: Depending on the shell used `echo "$SHELL"`, note the syntax difference in setting environmental variables:
```
export key=value
setenv key value
```
Upon issuing a certificate, `CF_Token` and `CF_Account_ID` will be saved in `~/.acme.sh/account.conf` and used for subsequent deployments.

5. Run the helper script `bash hpilo.sh` to issue a Let's Encrypt certificate to the iLO.
6. Repeat the steps above for other iLOs on your network.

To list all issued certificates `acme.sh --list`.



