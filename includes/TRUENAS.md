# Let's Encrypt FreeNAS/TrueNAS
## Preparation
Before undertaking a deployment:
1. Configure your local DNS resolver to resolve the FQDN of the server to its IP address. For example, `truenas.mydomain.com` must resolve to the server IP on the internal network.

## Deployment
1. Enter the Let's Encrypt jail `iocage console letsencrypt` and change to the truenas working directory `cd /truenas`.
2. Edit the file `truenas.cfg` with your favorite text editor. In its minimal form, for a FreeNAS server, it would look something like the following for a FreeNAS server:
```
   PASSWORD="alakazam"
   HOSTNAME="freenas"
   DOMAIN="mydomain.com"
```
   For a TrueNAS server, the API_KEY replaces the PASSWORD:
```
   API_KEY="1-DXcZ19sZoZFdGATIidJ8vMP6dxk3nHWz3XX876oxS7FospAGMQjkOft0h4itJDSP"
   HOSTNAME="truenas"
   DOMAIN="mydomain.com"
```

   The mandatory options are:
   - USERNAME: Username of the iLO administrator.
   - PASSWORD: The iLO administrator password.
   - HOSTNAME: The iLO hostname.
   - DOMAIN:   Your registered domain name.

   Other options with defaults include:
   - STAGING:  While finding your way around this resource, you're encouraged to set STAGING to 1 to avoid hitting Let's Encrypt rate limits. The default is 0.
   - DNSAPI:   A supported DNS provider for automatic DNS API integration https://github.com/acmesh-official/acme.sh/wiki/dnsapi. The default is Cloudflare (`dns_cf`). To use a different provider, for instance, Amazon Route53, set `DNSAPI="dns_aws"` in `hpilo.cfg`.
3. If this is your first deployment, set up the API credentials for your DNS provider https://github.com/acmesh-official/acme.sh/wiki/dnsapi, but do not issue a certificate just yet! For example, for Cloudflare:
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

4. Run the helper script `bash truenas.sh` to issue and deploy a Let's Encrypt certificate to the FreeNAS/TrueNAS server. 
5. Repeat the above steps for other servers on your network.

To list all issued certificates `acme.sh --list`. Acme.sh will manage the renewal and deployment of the certificates.
