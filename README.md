# WP In A Box

Script/s to install WordPress in a linux box without much effort

## Install procedure

- Rename `.envrc-sample` file as `.envrc` and insert as much information as possible
- Download `bootstrap.sh` and execute it.

```bash
# as root

apt-get install -y curl
curl -LSs https://github.com/pothi/wp-in-a-box/raw/master/bootstrap.sh -o ~/bootstrap.sh

# go through the script to understand what it does. you are ***warned***!
# vi ~/bootstrap.sh

apt-get install -y screen
screen
# execute it and face the consequences
bash ~/bootstrap.sh

# (optional) get rid of all the evidences of making the changes
# rm ~/bootstrap.sh

```

## Post-install

Only on Ubuntu 16.04, do the following...

- `sudo add-apt-repository ppa:certbot/certbot`
- `sudo apt update`
- `sudo apt install certbot`

## Wiki

For more documentation, supported / tested hosts, todo, etc, please see the [WP-In-A-Box wiki](https://github.com/pothi/wp-in-a-box/wiki).
