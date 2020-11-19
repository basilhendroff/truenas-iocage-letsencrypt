# Let's Encrypt FRITZ!Box
## Preparation
Before undertaking a deployment:
1. On the FRITZ!Box, add an exception for the FRITZ!Box FQDN under DNS Rebind Protection (FRITZ!Box UI > Home Network > Network > DNS Settings > DNS Rebind Protection).
2. Set up the FRITZ!Box to log in with a username and password (FRITZ!Box UI > System > FRITZ!Box Users > Login to the Home Network > Login for access to the Home Network). The default is to log in with a password only.
3. Configure your local DNS resolver to resolve the FQDN of the FRITZ!Box to its LAN IP address. For example, `fritzbox.mydomain.com` must resolve to the FRITZ!Box IP on the internal network.
## Deployment
Refer to [Deploy the cert to your FRITZ!Box router](https://github.com/acmesh-official/acme.sh/wiki/deployhooks#8-deploy-the-cert-to-your-fritzbox-router).
