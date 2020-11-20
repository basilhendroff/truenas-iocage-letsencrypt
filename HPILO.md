# Let's Encrypt HP iLO 
## Preparation
Before undertaking a deployment:
1. Ensure the iLO is updated with the latest firmware (iLO UI > Administration > Firmware) and the iLO hostname and domain fields (iLO UI > Network > iLO Dedicated Network Port > General) are configured.
2. Configure your local DNS resolver to resolve the FQDN of the iLO to its IP address. For example, `ilo.mydomain.com` must resolve to the iLO IP on the internal network.

## Deployment
1. Enter the Let's Encrypt jail `iocage console letsencrypt` and change to the hpilo working directory `cd /hpilo`.
2. Edit the file called `hpilo.cfg` with your favorite text editor. In its minimal form, it would look something like this:
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
- DNSAPI:   A supported DNS provider for automatic DNS API integration https://github.com/acmesh-official/acme.sh/wiki/dnsapi. The default is `dns_cf` (Cloudflare). For instance, to use Amazon Route53, `DNSAPI="dns_aws"`.
3. If this is your first deployment, continue with this step, otherwise, skip to the next step. Set up the API credentials for your DNS provider https://github.com/acmesh-official/acme.sh/wiki/dnsapi, but do not issue a certificate just yet! For example, for Cloudflare:
```
setenv CF_Token "sdfsdfsdfljlbjkljlkjsdfoiwje"
setenv CF_Account_ID "xxxxxxxxxxxxx"
```
When a certificate is first issued, `CF_Token` and `CF_Account_ID` are saved in `/config/account.conf` and used for subsequent deployments.

SIDE NOTE: The Let's Encrypt jail uses the C shell (csh). When setting environmental variables, use `setenv` rather than `export`. Note the difference in syntax.
```
export key=value
setenv key value
```

4. Run the helper script `bash hpilo.sh` to issue and deploy a Let's Encrypt certificate to the iLO. 
5. Repeat the above steps for other iLOs on your network.

To list all issued certificates `acme.sh --list`. Acme.sh will manage the renewal and deployment of the certificates.
