# Let's Encrypt FRITZ!Box
## Preparation
Before undertaking a deployment:
1. On the FRITZ!Box, add an exception for the FRITZ!Box FQDN under DNS Rebind Protection (FRITZ!Box UI > Home Network > Network > DNS Settings > DNS Rebind Protection).
2. Set up the FRITZ!Box to log in with a username and password (FRITZ!Box UI > System > FRITZ!Box Users > Login to the Home Network > Login for access to the Home Network). The default is to log in with a password only.
3. Configure your local DNS resolver to resolve the FQDN of the FRITZ!Box to its LAN IP address. For example, `fritzbox.mydomain.com` must resolve to the FRITZ!Box IP on the internal network.

## Deployment
1. If this is your first deployment, continue with this step, otherwise, skip to the next step. Set up the API credentials for your DNS provider https://github.com/acmesh-official/acme.sh/wiki/dnsapi, but do not issue a certificate just yet. For example, for Cloudflare:
```
export CF_Token="sdfsdfsdfljlbjkljlkjsdfoiwje"
export CF_Account_ID="xxxxxxxxxxxxx"
```
When a certificate is first issued, `CF_Token` and `CF_Account_ID` will be saved in `~/.acme.sh/account.conf` and used for subsequent deployments.

2. Refer to [Deploy the cert to your FRITZ!Box router](https://github.com/acmesh-official/acme.sh/wiki/deployhooks#8-deploy-the-cert-to-your-fritzbox-router) and set up the FRIT!Box credentials, but do not issue a certificate just yet.

NOTE: One FRITZ!Box per acme.sh server. It isn't straightforward for the acme.sh server to issue certificates to more than one FRITZ!Box. For more information, refer to [Can acme.sh deploy certs to more than one FRITZ!Box router?](https://community.letsencrypt.org/t/can-acme-sh-deploy-certs-to-more-than-one-fritz-box-router/137854) 

3. Issue a certificate using a command of the form shown. For example, if your DNS provider is Cloudflare:
`acme.sh --deploy --dns dns_cf -d fritzbox.mydomain.com --deploy-hook fritzbox`

To list the issued certificate `acme.sh --list`. Acme.sh will manage the renewal of the certificate.