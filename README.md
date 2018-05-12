# WP In A Box

Script/s to install WordPress in a linux box without much effort. For more details, please see the blog post at [https://www.tinywp.in/wp-in-a-box/](https://www.tinywp.in/wp-in-a-box/).

## Supported Platforms

+ Debian Stretch (9.x)
+ Ubuntu Xenial Xerus (16.04.x)
+ Ubuntu Bionic Beaver (18.04.x)

## Generic Goals

In sync with WordPress philosophy of “[decision, not options](https://wordpress.org/about/philosophy/)”.

## Performance Checklist

- Redis for object cache (with memcached as an option)
- WP Super Cache as full page cache (with Batcache as an alternative)
- PHP 7.x
- Nginx (no Apache, sorry)
- Varnish (planned, but no ETA)

## Security Considerations

- only ports 80, 443, and port for SSH are open.
- no phoning home.
- no external dependencies (such as third-party repositories, unless there is a strong reason to use it).
- automatic security updates (with an option to update everything).
- disable password authentication for root.
- Nginx (possibly with Naxsi WAF when h2 issue is resolved).
- umask 027 or 077.
- ACL integration.
- weekly logwatch (if email is supplied).
- isolated user for PhpMyAdmin.

## Implementation Details

- Agentless.
- Idempotent.
- Random username (like GoDaddy generates).
- Automatic restart of MySQL (and Varnish) upon failure.
- Automatic backup of site (files and DB) to AWS S3 or to GCP.
- Integrated wp-cli.
- Support for version control (git, hg).
- Composer pre-installed.
- Auto-update of almost everything (wp-cli, composer, certbot certs, wp minor versions, plugins, etc).

## Roadmap

- automatic Certbot / LetsEncrypt installation and renewal (like Caddy).
- automated setup of sites using backups.
- web interface (planned, but no ETA).

## Install procedure

- Rename `.envrc-sample` file as `.envrc` and insert as much information as possible
- Download `bootstrap.sh` and execute it.

```bash
# as root

apt install curl screen -y

# optional steps
# curl -LO https://github.com/pothi/wp-in-a-box/raw/master/.envrc-sample
# cp .envrc-sample .envrc
# nano .envrc

# download the bootstrap script
curl -LO https://github.com/pothi/wp-in-a-box/raw/master/bootstrap.sh

# please go through *any* script before executing it!
nano ~/bootstrap.sh

# execute it and wait for some time
screen bash bootstrap.sh

rm bootstrap.sh

```

## Wiki

For more documentation, supported / tested hosts, todo, etc, please see the [WP-In-A-Box wiki](https://github.com/pothi/wp-in-a-box/wiki).
