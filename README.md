validation-hooks-certbot-godaddy
=====================================
Pre and Post Validation Hooks DNS for manual mode of `certbot` with GoDaddy domains

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

What is it ?
-----------
This repository contains pre and post validation hooks to be used with `certbot` command in `manual mode` to certify a GoDaddy Domains with DNS-01 method.

More informations are available on [Certbot Doc](https://certbot.eff.org/docs/using.html#pre-and-post-validation-hooks)

Required package
----------
This script is a shell script based on `/bin/bash`.
It uses following command tools :
```
curl
dig
```

It depends on several packages :
```
yum install curl
# dig command depends on bind-utils package
yum install bind-utils
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

For `authenticator_godaddy.sh`, you must set manually following variables :
 * `CERTBOT_DOMAIN`
 * `CERTBOT_VALIDATION`

For example, if your domain is `auth.foo.mydomain.com`, these variables must set like :
```
# Uncomment this lines only to test this script manually
CERTBOT_DOMAIN="auth.foo.mydomain.com"
CERTBOT_VALIDATION="test_value"
```

Once the `authenticator_godaddy.sh` script ended, your domain must be upgrade with `_acme-challenge.auth.foo` TXT record with `test_value` as value.  

However, these lines must be commented in `normal mode` because `$CERTBOT_DOMAIN` and `$CERTBOT_VALIDATION` variables is defined by `certbot` command.

(Optional) Separate credentials
--------
It is recommended to store separately credentials from script to avoid a security risk.
By default, these scripts will try to load your credentials from `secrets` file in :
`/etc/certbot/$CERTBOT_DOMAIN/secrets`

An sample of `secrets` file, named `secrets.sample`, is available to help you how it must be formated.

*Similarly, you can modify default path of `secrets` file used, by editing `SECRET_FILE` variable.*

Testing systems
----------
- macSierra
- CentOS 7
