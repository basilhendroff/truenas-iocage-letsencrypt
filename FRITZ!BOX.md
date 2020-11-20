# Let's Encrypt FRITZ!Box
## Preparation
Before undertaking a deployment:
1. On the FRITZ!Box, add an exception for the FRITZ!Box FQDN under DNS Rebind Protection (FRITZ!Box UI > Home Network > Network > DNS Settings > DNS Rebind Protection).
2. Set up the FRITZ!Box to log in with a username and password (FRITZ!Box UI > System > FRITZ!Box Users > Login to the Home Network > Login for access to the Home Network). The default is to log in with a password only.
3. Configure your local DNS resolver to resolve the FQDN of the FRITZ!Box to its LAN IP address. For example, `fritzbox.mydomain.com` must resolve to the FRITZ!Box IP on the internal network.

## Deployment
1. If this is your first deployment, set up the API credentials for your DNS provider https://github.com/acmesh-official/acme.sh/wiki/dnsapi and issue a certificate. For example, for Cloudflare:
```
setenv CF_Token "sdfsdfsdfljlbjkljlkjsdfoiwje"
setenv CF_Account_ID "xxxxxxxxxxxxx"
acme.sh --issue --dns dns_cf -d fritzbox.mydomain.com
```
SIDE NOTE: The Let's Encrypt jail uses the C shell (csh). When setting environmental variables, use `setenv` rather than `export`. Note the difference in syntax.
```
export key=value
setenv key value
```
When a certificate is first issued, `CF_Token` and `CF_Account_ID` will be saved in `~/.acme.sh/account.conf` and used for subsequent deployments.

2. If this is not your first deployment, just issue a certificate. For example, if your DNS provider is Cloudflare:
```
acme.sh --issue --dns dns_cf -d fritzbox.mydomain.com
```
3. Now deploy the certificate to your FRITZ!Box [Deploy the cert to your FRITZ!Box router](https://github.com/acmesh-official/acme.sh/wiki/deployhooks#8-deploy-the-cert-to-your-fritzbox-router). For example:
```
setenv DEPLOY_FRITZBOX_USERNAME "admin"
setenv DEPLOY_FRITZBOX_PASSWORD "alakazam"
setenv DEPLOY_FRITZBOX_URL "https://fritzbox.mydomain.com"
acme.sh --deploy -d fritzbox.mydomain.com --deploy-hook fritzbox
```
NOTE: One FRITZ!Box can be set up per acme.sh server. It isn't straightforward for the acme.sh server to issue certificates to more than one FRITZ!Box. For more information, refer to the Let's Encrypt Community Forum thread [Can acme.sh deploy certs to more than one FRITZ!Box router?](https://community.letsencrypt.org/t/can-acme-sh-deploy-certs-to-more-than-one-fritz-box-router/137854) 


To list the issued certificate `acme.sh --list`. Acme.sh will manage the renewal of the certificate.
