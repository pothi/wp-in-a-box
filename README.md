# WP In A Box

Script/s to install LEMP in a linux box. This LEMP stack is fine-tuned towards WordPress installations. It may work for other PHP based applications, too. For more details, please see the blog post at [https://www.tinywp.in/wp-in-a-box/](https://www.tinywp.in/wp-in-a-box/).

There are a number of similar scripts available on the internet. The unique feature of this repo is in [security considerations](https://github.com/pothi/wp-in-a-box#security-considerations).

## Supported Platforms

Ubuntu

+ [Ubuntu Jammy Jellyfish (22.04.x)](https://github.com/pothi/wp-in-a-box/blob/main/bootstrap-ubuntu-jammy.sh)
+ [Ubuntu Focal Fossa (20.04.x)](https://github.com/pothi/wp-in-a-box/blob/main/bootstrap-ubuntu-focal.sh)
+ Ubuntu Bionic Beaver (18.04.x)
+ Ubuntu Xenial Xerus (16.04.x)

Debian

+ [Debian Bookworm (12.x)](https://github.com/pothi/wp-in-a-box/blob/main/bookworm-deb-boot.sh)
+ [Debian Bullseye (11.x)](https://github.com/pothi/wp-in-a-box/blob/main/bootstrap-debian-bullseye.sh)
+ [Debian Buster (10.x)](https://github.com/pothi/wp-in-a-box/blob/main/bootstrap-debian-buster.sh)
+ Debian Stretch (9.x)

## Generic Goals

In sync with WordPress philosophy of “[decision, not options](https://wordpress.org/about/philosophy/)”.

## Performance Considerations

- No added bloatware
- Redis for object cache (available as an optional package)
- Full page cache support (WP Super Cache, WP Rocket and WP Fastest Cache)
- PHP 8 (or lower when necessary)
- Nginx (no Apache, sorry)
- Varnish (planned, but no ETA)
- Swap

## Security Considerations

- No phoning home.
- No external dependencies (such as third-party repositories, unless there is a strong reason to use it).
- Automatic security updates (with an option to update everything).
- Disable password authentication for root.
- Nginx (possibly with Naxsi WAF when h2 issue is resolved).
- Umask 027 or 077.
- ACL integration.
- Weekly logwatch (if email is supplied).
- Isolated user for PhpMyAdmin.
- PHP user and Nginx user run under different username.
- Only ports 80, 443, and port for SSH are open.

## Implementation Details

- Agentless.
- Idempotent.
- Random username (like GoDaddy generates).
- Automatic restart of MySQL (and Varnish) upon failure.
- Integrated wp-cli.
- Support for version control (git, hg).
- Composer pre-installed.
- Auto-update of almost everything (wp-cli, composer, certbot certs, etc).

## Roadmap

- Automatic Certbot / LetsEncrypt installation and renewal (like Caddy).
- Automated setup of sites using backups.
- Web interface (planned, but no ETA).
- Automatic backup of site/s (files and DB) to AWS S3 or to GCP.

## Install procedure

- Rename `.envrc-sample` file as `.envrc` and insert as much information as possible
- Download `bootstrap.sh` and execute it.

```bash
# as root

apt install curl screen -y

# optional steps
# curl -LO https://github.com/pothi/wp-in-a-box/raw/main/.envrc-sample
# cp .envrc-sample .envrc
# nano .envrc

# download the bootstrap script
curl -LO https://github.com/pothi/wp-in-a-box/raw/main/bootstrap.sh

# please do not trust any script on the internet or github
# so, please go through it!
nano ~/bootstrap.sh

# execute it and wait for some time
# screen bash bootstrap.sh
# or simply
bash bootstrap.sh

# wait for the installation to get over.
# it can take approximately 5 minutes on a 2GB server
# it depends on CPU power too

# we no longer needs bootstrap.sh file
rm bootstrap.sh

# to see the credentials to log in to the server from now
# this is the important step. you can't login as root from now on
cat ~/.envrc

```

## What you get at the end of the installation

You may find the following details at `~/.envrc` file...

- a SSH user (prefixed with `ssh_`) with sudo privileges (use it only to manage the server such as to create a new MySQL database or to create a new vhost entry for Nginx)
- a chrooted SFTP user, prefixed with `sftp_web_`, with its home directory at `/home/web` along with some common directories(such as `~/log`, `~/sites`, etc) created already. (you may give it to your developer to access the file system such as to upload a new theme, etc)
- a dedicated MySQL username (and password) with all the privileges as `root` user. This can be used to access MySQL via PhpMyAdmin, as `root` user can only access MySQL via cli.

## Where to install WordPress & How to install it

- PHP runs as SFTP user. So, please install WordPress **as** SFTP user at `/home/web/sites/example.com/public`.
- Configure Nginx using pre-defined templates that can be found at the companion repo [WordPress-Nginx](https://github.com/pothi/wordpress-nginx). That repo is already installed. You just have to copy / paste one of [the templates](https://github.com/pothi/wordpress-nginx/tree/main/sites-available) to fit your domain name.
- If you wish to deploy SSL, a [Let's Encrypt](https://letsencrypt.org/) client is already installed. Please use the command `certbot certonly --webroot -w /home/web/sites/example.com/public -d example.com -d www.example.com`. The renewal script is already in place as a cron entry. So, you don't have to create a new entry. To know more about this client library and to know more about the available options, please visit [https://certbot.eff.org/](https://certbot.eff.org/) .

## Known Limitations

- SFTP user can not create or upload new files and folders at `$HOME`, but can create or upload inside other existing directories. This is [a known limitation](https://wiki.archlinux.org/index.php/SFTP_chroot#Write_permissions) when we use SFTP capability of built-in OpenSSH server.

## Wiki

For more documentation, information, supported/tested hosts, todo, etc, please see the [WP-In-A-Box wiki](https://github.com/pothi/wp-in-a-box/wiki).
