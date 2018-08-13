# Ubuntu-Nginx-Web-Server Documentation

Table Of Contents
<!-- TOC -->

- [Ubuntu-Nginx-Web-Server Documentation](#ubuntu-nginx-web-server-documentation)
  - [Initial Configuration](#initial-configuration)
    - [System update and packages cleanup](#system-update-and-packages-cleanup)
    - [Install useful packages](#install-useful-packages)
    - [Tweak Kernel & Increase open files limits](#tweak-kernel--increase-open-files-limits)
    - [disable transparent hugepage for redis](#disable-transparent-hugepage-for-redis)
  - [EasyEngine Setup](#easyengine-setup)
    - [Install MariaDB 10.3](#install-mariadb-103)
    - [MySQL Tuning](#mysql-tuning)
  - [Install EasyEngine](#install-easyengine)
    - [enable ee bash_completion](#enable-ee-bashcompletion)
    - [Install Nginx, php5.6, php7.0, postfix, redis and configure EE backend](#install-nginx-php56-php70-postfix-redis-and-configure-ee-backend)
    - [Set your email instead of root@localhost](#set-your-email-instead-of-rootlocalhost)
    - [Install Composer - Fix phpmyadmin install issue](#install-composer---fix-phpmyadmin-install-issue)
    - [Allow shell for www-data for SFTP usage](#allow-shell-for-www-data-for-sftp-usage)
  - [PHP 7.1 & 7.2 Setup](#php-71--72-setup)
    - [Install php7.1-fpm](#install-php71-fpm)
    - [Install php7.2-fpm](#install-php72-fpm)
    - [add nginx upstreams](#add-nginx-upstreams)
    - [add ee common configuration](#add-ee-common-configuration)
  - [Compile lastest Nginx release](#compile-lastest-nginx-release)
  - [Custom configurations](#custom-configurations)
    - [clean php-fpm php.ini configuration](#clean-php-fpm-phpini-configuration)
    - [Nginx optimized configurations](#nginx-optimized-configurations)
    - [Nginx configuration for netdata & new upstreams](#nginx-configuration-for-netdata--new-upstreams)
    - [Increase Nginx open files limits](#increase-nginx-open-files-limits)
    - [wpcommon-php7x configurations](#wpcommon-php7x-configurations)
  - [Security](#security)
    - [Harden SSH Security](#harden-ssh-security)
    - [UFW](#ufw)
    - [Custom jails for fail2ban](#custom-jails-for-fail2ban)
    - [Secure Memcached server](#secure-memcached-server)
  - [Optional tools](#optional-tools)
    - [ee-acme-sh](#ee-acme-sh)
    - [netdata](#netdata)
    - [bash-snippets](#bash-snippets)
    - [nanorc - Improved Nano Syntax Highlighting Files](#nanorc---improved-nano-syntax-highlighting-files)
    - [ucaresystem - script to update & cleanup packages easily](#ucaresystem---script-to-update--cleanup-packages-easily)
    - [Custom Nginx error pages](#custom-nginx-error-pages)
    - [WP-CLI](#wp-cli)
      - [Add bash-completion for user www-data](#add-bash-completion-for-user-www-data)

<!-- /TOC -->

## Initial Configuration

### System update and packages cleanup

```bash
apt-get update && apt-get upgrade -y && apt-get autoremove --purge -y && apt-get clean
```

### Install useful packages

```bash
sudo apt install haveged curl git unzip zip fail2ban htop nload nmon ntp -y
```

### Tweak Kernel & Increase open files limits

[source sysctl.conf](https://github.com/VirtuBox/ubuntu-nginx-web-server/blob/master/etc/sysctl.conf) - [limits.conf source](https://github.com/VirtuBox/ubuntu-nginx-web-server/blob/master/etc/security/limits.conf)

```bash
modprobe tcp_htcp
wget -O /etc/sysctl.conf https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/files/etc/sysctl.conf
sysctl -p
wget -O /etc/security/limits.conf https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/files/etc/security/limits.conf
```

### disable transparent hugepage for redis

```bash
echo never > /sys/kernel/mm/transparent_hugepage/enabled
```

* * *

## EasyEngine Setup

### Install MariaDB 10.3

Instructions available in [VirtuBox Knowledgebase](https://kb.virtubox.net/knowledgebase/install-latest-mariadb-release-easyengine/)

```bash
curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup \
| sudo bash -s -- --mariadb-server-version=10.3 --skip-maxscale
sudo apt update && sudo apt install mariadb-server -y
```

### MySQL Tuning

You can download my example of my.cnf, optimized for VPS with 4GB RAM. [my.cnf source](https://github.com/VirtuBox/ubuntu-nginx-web-server/blob/master/etc/mysql/my.cnf)

```bash
wget -O /etc/mysql/my.cnf https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/files/etc/mysql/my.cnf
```

It include modification of innodb_log_file_size variable, so you need to use the following commands to apply the new configuration :

```bash
sudo service mysql stop

sudo mv /var/lib/mysql/ib_logfile0 /var/lib/mysql/ib_logfile0.bak
sudo mv /var/lib/mysql/ib_logfile1 /var/lib/mysql/ib_logfile1.bak

sudo service mysql start
```

Increase MariaDB open files limits

```bash
wget -O /etc/systemd/system/mariadb.service.d/limits.conf https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/files/etc/systemd/system/mariadb.service.d/limits.conf

sudo systemctl daemon-reload
sudo systemctl restart mariadb
```

## Install EasyEngine

```bash
# noninteractive install - you can replace $USER with your username & root@$HOSTNAME by your email
sudo bash -c 'echo -e "[user]\n\tname = $USER\n\temail = root@$HOSTNAME" > $HOME/.gitconfig'

wget -qO ee rt.cx/ee && bash ee
```

### enable ee bash_completion

```bash
source /etc/bash_completion.d/ee_auto.rc
```

### Install Nginx, php5.6, php7.0, postfix, redis and configure EE backend

```bash
ee stack install
ee stack install --php7 --redis --admin --phpredisadmin
```

### Set your email instead of root@localhost

```bash
echo 'root: my.email@address.com' >> /etc/aliases
newaliases
```

### Install Composer - Fix phpmyadmin install issue

```bash
cd ~/ ||exit
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/bin/composer

chown www-data:www-data /var/www
sudo -u www-data -H composer update -d /var/www/22222/htdocs/db/pma/
```

### Allow shell for www-data for SFTP usage

```bash
usermod -s /bin/bash www-data
```

## PHP 7.1 & 7.2 Setup

### Install php7.1-fpm

```bash
# php7.1-fpm
apt update && apt install php7.1-fpm php7.1-cli php7.1-zip php7.1-opcache php7.1-mysql php7.1-mcrypt php7.1-mbstring php7.1-json php7.1-intl \
php7.1-gd php7.1-curl php7.1-bz2 php7.1-xml php7.1-tidy php7.1-soap php7.1-bcmath -y php7.1-xsl

wget -O /etc/php/7.1/fpm/pool.d/www.conf https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/php/7.1/fpm/pool.d/www.conf

wget -O /etc/php/7.1/fpm/php.ini https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/php/7.1/fpm/php.ini
service php7.1-fpm restart
```

### Install php7.2-fpm

```bash
# php7.2-fpm
apt update && apt install php7.2-fpm php7.2-xml php7.2-bz2  php7.2-zip php7.2-mysql  php7.2-intl php7.2-gd php7.2-curl php7.2-soap php7.2-mbstring -y

wget -O /etc/php/7.2/fpm/pool.d/www.conf https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/php/7.2/fpm/pool.d/www.conf

wget -O /etc/php/7.2/fpm/php.ini https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/php/7.2/fpm/php.ini
service php7.2-fpm restart
```

### add nginx upstreams

```bash
wget -O /etc/nginx/conf.d/upstream.conf https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/files/etc/nginx/conf.d/upstream.conf
service nginx reload
```

### add ee common configuration

```bash
cd /etc/nginx/common || exit
wget https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/files/common.zip
unzip common.zip
```

## Compile lastest Nginx release
[nginx-ee script](https://github.com/VirtuBox/nginx-ee)

```bash
bash <(wget -O - https://raw.githubusercontent.com/VirtuBox/nginx-ee/master/nginx-build.sh)
```

* * *

## Custom configurations

### clean php-fpm php.ini configuration

```bash
# PHP 7.0
wget -O /etc/php/7.0/fpm/php.ini https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/files/etc/php/7.0/fpm/php.ini
service php7.0-fpm restart
```

### Nginx optimized configurations

```bash
# TLSv1.2 TLSv1.3 only
wget -O /etc/nginx/nginx.conf https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/files/etc/nginx/nginx.conf
```

### Nginx configuration for netdata & new upstreams

```bash
# custom conf for netdata metrics (php-fpm & nginx status pages)
wget -O /etc/nginx/sites-available/default  https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/files/etc/nginx/sites-available/default

# add netdata, php7.1 and php7.2 upstream
wget -O /etc/nginx/conf.d/upstream.conf https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/files/etc/nginx/conf.d/upstream.conf

# add nginx reverse-proxy for netdata on https://yourserver.hostname:22222/netdata/
wget -O /etc/nginx/sites-available/22222 https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/files/etc/nginx/sites-available/22222
```

### Increase Nginx open files limits

```bash
sudo mkdir -p /etc/systemd/system/nginx.service.d
wget -O /etc/systemd/system/nginx.service.d/limits.conf https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/files/etc/systemd/system/nginx.service.d/limits.conf

sudo systemctl daemon-reload
sudo systemctl restart nginx.service
```

### wpcommon-php7x configurations

- webp rewrite rules added
- DoS attack CVE fix added
- php7.1 & php7.2 configuration added

```bash
# 1) add webp mapping
wget -O /etc/nginx/conf.d/webp.conf  https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/files/etc/nginx/conf.d/webp.conf

# 2) wpcommon files
# php7
wget -O /etc/nginx/common/wpcommon-php7.conf https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/files/etc/nginx/common/wpcommon-php7.conf

# php7.1
wget -O /etc/nginx/common/wpcommon-php71.conf https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/files/etc/nginx/common/wpcommon-php71.conf

# php7.2
wget -O /etc/nginx/common/wpcommon-php72.conf https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/files/etc/nginx/common/wpcommon-php72.conf

nginx -t
service nginx reload
```

* * *

## Security

### Harden SSH Security

WARNING : SSH Configuration with root login allowed with ed25519 & ECDSA SSH keys only  [source](https://github.com/VirtuBox/ubuntu-nginx-web-server/blob/master/etc/ssh/sshd_config)

    wget -O /etc/ssh/sshd_config https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/files/etc/ssh/sshd_config

### UFW

Instructions available in [VirtuBox Knowledgebase](https://kb.virtubox.net/knowledgebase/ufw-iptables-firewall-configuration-made-easier/)

```bash
# enable ufw log - allow outgoing - deny incoming
ufw logging low
ufw default allow outgoing
ufw default deny incoming

# SSH - DNS - HTTP/S - FTP - NTP - SNMP - Librenms - Netdata - EE Backend
ufw allow 22
ufw allow 53
ufw allow http
ufw allow https
ufw allow 21
ufw allow 123
ufw allow 161
ufw allow 6556
ufw allow 19999
ufw allow 22222

# enable UFW
ufw enable
```

### Custom jails for fail2ban

- wordpress bruteforce
- ssh
- recidive (after 3 bans)
- backend http auth
- nginx bad bots

```bash
wget -O /etc/fail2ban/filter.d/ddos.conf https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/files/etc/fail2ban/filter.d/ddos.conf
wget -O /etc/fail2ban/filter.d/ee-wordpress.conf https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/files/etc/fail2ban/filter.d/ee-wordpress.conf
wget -O /etc/fail2ban/filter.d/nginx-forbidden.conf https://virtubox.github.io/ubuntu-nginx-web-server/files/etc/fail2ban/filter.d/nginx-forbidden.conf
wget -O /etc/fail2ban/jail.d/custom.conf https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/files/etc/fail2ban/jail.d/custom.conf
wget -O  /etc/fail2ban/jail.d/ddos.conf https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/files/etc/fail2ban/jail.d/ddos.conf

fail2ban-client reload
```

### Secure Memcached server

```bash
echo '-U 0' >> /etc/memcached.conf
sudo systemctl restart memcached
```

## Optional tools

### ee-acme-sh

[Github repository](https://raw.githubusercontent.com/VirtuBox/ee-acme-sh/) - Script to setup letsencrypt certificates using acme.sh on EasyEngine servers

* subdomain support
* ivp6 support
* wildcards certificates support

```bash
wget -O install-ee-acme.sh https://raw.githubusercontent.com/VirtuBox/ee-acme-sh/master/install.sh
chmod +x install-ee-acme.sh
./install-ee-acme.sh

# enable acme.sh & ee-acme-sh
source .bashrc
```

### netdata

[Github repository](https://github.com/firehol/netdata)

```bash

bash <(curl -Ss https://my-netdata.io/kickstart.sh) all

# save 40-60% of netdata memory
echo 1 >/sys/kernel/mm/ksm/run
echo 1000 >/sys/kernel/mm/ksm/sleep_millisecs

# disable email notifications
sed -i 's/SEND_EMAIL="YES"/SEND_EMAIL="NO"/' /etc/netdata/health_alarm_notify.conf
service netdata restart
```

### bash-snippets

[Github repository](https://github.com/alexanderepstein/Bash-Snippets)

```bash
git clone https://github.com/alexanderepstein/Bash-Snippets
cd Bash-Snippets
git checkout v1.22.0
./install.sh cheat
```

usage : `cheat <command>`

```bash
root@vps:~ cheat cat
# cat

# Print and concatenate files.

# Print the contents of a file to the standard output:
  cat file

# Concatenate several files into the target file:
  cat file1 file2 > target_file

# Append several files into the target file:
  cat file1 file2 >> target_file

# Number all output lines:
  cat -n file
```

### nanorc - Improved Nano Syntax Highlighting Files

[Github repository](https://github.com/scopatz/nanorc)

```bash
wget https://raw.githubusercontent.com/scopatz/nanorc/master/install.sh -O- | sh
```

### ucaresystem - script to update & cleanup packages easily

```bash
sudo add-apt-repository ppa:utappia/stable -y
sudo apt update
sudo apt install ucaresystem-core -y
```

Run server maintenance with the command :

```bash
sudo ucaresystem-core
```

### Custom Nginx error pages

[Github Repository](https://github.com/alexphelps/server-error-pages)

Installation

```bash
# clone the github repository
sudo -u www-data -H git clone https://github.com/alexphelps/server-error-pages.git /var/www/error

# download nginx configuration
wget -O /etc/nginx/common/error_pages.conf https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/files/etc/nginx/common/error_pages.conf
```

Then include this configuration in your nginx vhost by adding the following line

```bash
include common/error_pages.conf;
```

### WP-CLI

#### Add bash-completion for user www-data

```bashrc
# download wp-cli bash_completion
wget -O /etc/bash_completion.d/wp-completion.bash https://raw.githubusercontent.com/wp-cli/wp-cli/master/utils/wp-completion.bash

# change /var/www owner
chown www-data:www-data /var/www

# download .profile & .bashrc for www-data
wget -O /var/www/.profile https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/docs/files/var/www/.profile
wget -O /var/www/.bashrc https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/docs/files/var/www/.bashrc

# set owner
chown www-data:www-data /var/www/.profile
chown www-data:www-data /var/www/.bashrc
```

