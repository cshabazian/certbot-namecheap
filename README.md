# Certbot Namecheap

Forked from https://github.com/haomingyin/certbot-namecheap-hook with an improved (in my opinion) script to obtain and renew SSL certificates from LetsEncrypt using certbot when namecheap is your registry.
The script can be used to automatically obtain/renew wildcard certificates using [Certbot](https://Certbot.eff.org/).

## Introduction

Every certificate obtianed from certbot has a lifetime limitation of three months. Current methods require you to manually renew certs every three months when you have namecheap as your registrar as there is no mechanism to automate the issuance and renewal using certbot (like with other providers such as cloudflare). This repository uses namecheap.py from the above forked repo to access the Namecheap API and update your DNS record to allow certbot automation when namecheap is your registrar.

## Get Started

### Pre-requirements

- Ensure you have your Namecheap account API key at hand. Refer to [get API key](https://www.namecheap.com/support/api/intro.aspx).

- Python 3 is required to get the script working

### Run Scripts

`namecert.sh` is a bash script which you can run to obtain a certificate and create a cron job to automatically check for renewal daily.

## Reference

- certbot-namecheap-hook [Repo](https://github.com/haomingyin/certbot-namecheap-hook)
- Namecheap official [API](https://www.namecheap.com/support/api/intro.aspx).
- Certbot [user guide](https://Certbot.eff.org/docs/using.html)
