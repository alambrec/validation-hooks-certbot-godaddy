validation-hooks-certbot-godaddy
=====================================
Pre and Post Validation Hooks DNS for manual mode of `certbot` with GoDaddy domains

What is it ?
-----------
This repository contains pre and post validation hooks to be used with `certbot` command in `manual mode` to certify a GoDaddy Domains with DNS-01 method.

More informations are available on [Certbot Doc](https://certbot.eff.org/docs/using.html#pre-and-post-validation-hooks)

Required package
----------
This script is a shell script based on `/bin/sh`.
It uses following command tools :
```
curl
host
```

It depends on several packages :
```
yum install curl
```

How to
----------
1. Download this script on your system
2. Replace SHELL variables `API_KEY`, `API_SECRET` and `DOMAIN` in this script to match them with yours values
3. Run `certbot` in `manual mode` with this two scripts as arguments :
```
certbot certonly --manual --preferred-challenges=dns --manual-auth-hook ./authenticator_godaddy.sh --manual-cleanup-hook ./cleanup_godaddy.sh -d $YOUR_DOMAIN
```
4. If `certbot` return success, you would get your new certificate on your system

Debug
----------
If you have any problems, you can run separately this script.
For `authenticator_godaddy.sh`, you must uncomment the line 17 to set manually `$CERTBOT_VALIDATION` variable.
However, the line 17 must be commented in `normal mode` because `$CERTBOT_VALIDATION` variable is defined by `certbot` command.

Testing systems
----------
- macSierra
- CentOS 7 


