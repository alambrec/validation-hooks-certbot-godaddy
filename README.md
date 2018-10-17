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
2. Replace SHELL variables `API_KEY` and `API_SECRET` in this script to match them with yours values
3. Run `certbot` in `manual mode` with this two scripts as arguments :
```
certbot certonly --manual --preferred-challenges=dns --manual-auth-hook ./authenticator_godaddy.sh --manual-cleanup-hook ./cleanup_godaddy.sh -d $YOUR_DOMAIN
```
4. If `certbot` return success, you would get your new certificate on your system

Debug
----------
If you have any problems, you can run separately this script.

For `authenticator_godaddy.sh`, you must uncomment the lines 16 and 17 to set manually following variables :
 * `$CERTBOT_DOMAIN`
 * `$CERTBOT_VALIDATION`

For example, if your domain is `auth.foo.mydomain.com`, these variables must set like :
```
# Uncomment this lines only to test this script manually
CERTBOT_DOMAIN="auth.foo.mydomain.com"
CERTBOT_VALIDATION="test_value"
```

One the `authenticator_godaddy.sh` script ended, your domain must be upgrade with `_acme-challenge.auth.foo` TXT record with `test_value` as value.  

However, the lines 16 and 17 must be commented in `normal mode` because `#CERTBOT_DOMAIN` and `$CERTBOT_VALIDATION` variables is defined by `certbot` command.

Testing systems
----------
- macSierra
- CentOS 7 


