# Optimized configuration for WordOps running on Ubuntu server

## Server Stack

- Ubuntu 16.04/18.04 LTS
- Nginx 1.17.x / 1.16.x
- PHP-FPM 7.2/7.3
- MariaDB 10.3
- REDIS 5.0
- Memcached
- Fail2ban
- Netdata
- UFW

--------------------------------------------------------------------------------

![](https://img.shields.io/github/license/virtubox/ubuntu-nginx-web-server.svg?style=flat) ![last-commit](https://img.shields.io/github/last-commit/virtubox/ubuntu-nginx-web-server.svg?style=flat) ![stars](https://img.shields.io/github/stars/VirtuBox/ubuntu-nginx-web-server.svg?style=flat)

### Info

**As EasyEngine v3 will no longer receive any updates, configurations available in this repository are being updated for [WordOps](https://wordops.net/) (EEv3 fork).**

We are currently contributing to WordOps project and several parts of this repository are already included in WordOps.

All previous configurations are still available in the branch [easyengine-v3](https://github.com/VirtuBox/ubuntu-nginx-web-server/tree/easyengine-v3).

--------------------------------------------------------------------------------

- [Initial configuration](#initial-configuration)

  - [System update and packages cleanup](#system-update-and-packages-cleanup)
  - [Install useful packages](#install-useful-packages)
  - [Clone the repository](#clone-the-repository)
  - [Updating the repository](#updating-the-repository)
  - [Tweak Kernel & Increase open files limits](#tweak-kernel--increase-open-files-limits)
  - [disable transparent hugepage for redis](#disable-transparent-hugepage-for-redis)

- [WordOps Setup](#wordops-setup)

  - [Install MariaDB 10.3](#install-mariadb-103)
  - [MySQL Tuning](#mysql-tuning)
  - [Increase MariaDB open files limits](#increase-mariadb-open-files-limits)
  - [Setup cronjob to optimize your MySQL databases and repair them if needed](#setup-cronjob-to-optimize-your-mysql-databases-and-repair-them-if-needed)

- [Install WordOps](#install-wordops)

  - [enable wo bash_completion](#enable-wo-bash_completion)
  - [Install Nginx, php7.2, and configure WO backend](#install-nginx-php72-and-configure-wo-backend)
  - [Set your email instead of root@localhost](#set-your-email-instead-of-rootlocalhost)
  - [Install Composer - Fix phpmyadmin install issue](#install-composer---fix-phpmyadmin-install-issue)
  - [Allow shell for www-data for SFTP usage](#allow-shell-for-www-data-for-sftp-usage)
  - [Set the proper alternative for /usr/bin/php](#set-the-proper-alternative-for-usrbinphp)

- [NGINX Configuration](#nginx-configuration)

  - [Additional Nginx configuration (/etc/nginx/conf.d)](#additional-nginx-configuration-etcnginxconfd)
  - [Compile last Nginx mainline release with nginx-ee](#compile-last-nginx-mainline-release-with-nginx-ee-scripthttpsgithubcomvirtuboxnginx-ee)
  - [Custom configurations](#custom-configurations)
  - [Nginx optimized configurations](#nginx-optimized-configurations-choose-one-of-them)
  - [Increase Nginx open files limits](#increase-nginx-open-files-limits)

- [Security](#security)

  - [Harden SSH Security](#harden-ssh-security)
  - [UFW](#ufw)
  - [Custom jails for fail2ban](#custom-jails-for-fail2ban)
  - [Secure Memcached server](#secure-memcached-server)

- [Optional](#optional)

  - [proftpd](#proftpd)

    - [Install proftpd](#install-proftpd)
    - [Adding FTP users](#adding-ftp-users)

  - [ee-acme-sh](#ee-acme-sh)

  - [netdata](#netdata)

  - [cht.sh (cheat)](#chtsh-cheat)

  - [nanorc - Improved Nano Syntax Highlighting Files](#nanorc---improved-nano-syntax-highlighting-files)

  - [Add WP-CLI & bash-completion for user www-data](#add-wp-cli--bash-completion-for-user-www-data)

- [Cleanup previous EasyEngine v3](#cleanup-previous-easyengine-v3)

  - [Removing previous php versions](#removing-previous-php-versions)

--------------------------------------------------------------------------------

Configuration files with comments available by following the link **source**

## Initial configuration

### System update and packages cleanup

```bash
apt-get update && apt-get dist-upgrade -y && apt-get autoremove --purge -y && apt-get clean
```

### Install useful packages

```bash
sudo apt-get install haveged curl git unzip zip fail2ban htop nload nmon ntp gnupg gnupg2 wget pigz tree ccze mycli -y
```

### Clone the repository

```bash
git clone https://github.com/VirtuBox/ubuntu-nginx-web-server.git $HOME/ubuntu-nginx-web-server
```

### Updating the repository

```bash
git -C $HOME/ubuntu-nginx-web-server pull origin master
```

### Tweak Kernel & Increase open files limits

<span style="color: red">Included by default in WordOps - this may not be needed anymore</span>

[source sysctl.conf](https://github.com/VirtuBox/ubuntu-nginx-web-server/blob/master/etc/sysctl.conf) - [limits.conf source](https://github.com/VirtuBox/ubuntu-nginx-web-server/blob/master/etc/security/limits.conf)

```bash
cp $HOME/ubuntu-nginx-web-server/etc/sysctl.d/60-ubuntu-nginx-web-server.conf /etc/sysctl.d/60-ubuntu-nginx-web-server.conf
```

Ubuntu 16.04 LTS do not support the new tcp congestion control algorithm bbr, we will use htcp instead.

```bash
# On ubuntu 18.04 LTS
modprobe tcp_bbr && echo 'tcp_bbr' >> /etc/modules-load.d/bbr.conf
echo -e '\nnet.ipv4.tcp_congestion_control = bbr\nnet.ipv4.tcp_notsent_lowat = 16384' >> /etc/sysctl.d/60-ubuntu-nginx-web-server.conf

# On ubuntu 16.04 LTS
modprobe tcp_htcp && echo 'tcp_htcp' >> /etc/modules-load.d/htcp.conf
echo 'net.ipv4.tcp_congestion_control = htcp' >> /etc/sysctl.d/60-ubuntu-nginx-web-server.conf
```

Then to apply the configuration :

```bash
sysctl -e -p /etc/sysctl.d/60-ubuntu-nginx-web-server.conf
```

Increase openfiles limits

```bash
sudo bash -c 'echo -e "*         hard    nofile      500000\n*         soft    nofile      500000\nroot      hard    nofile      500000\nroot      soft    nofile      500000\n"  >> /etc/security/limits.conf'
```

### disable transparent hugepage for redis

```bash
echo never > /sys/kernel/mm/transparent_hugepage/enabled
```

--------------------------------------------------------------------------------

## WordOps Setup

### Install MariaDB 10.3

<span style="color: red">Included by default in WordOps - this may not be needed anymore</span>

Instructions available in [VirtuBox Knowledgebase](https://kb.virtubox.net/knowledgebase/install-latest-mariadb-release-easyengine/)

```bash
bash <(wget -qO - https://downloads.mariadb.com/MariaDB/mariadb_repo_setup) --mariadb-server-version=10.3 --skip-maxscale -y
sudo apt update && sudo apt install mariadb-server -y
```

Secure MariaDB after install by running the command :

```bash
mysql_secure_installation
```

### MySQL Tuning

You can download my example of my.cnf, optimized for VPS with 4GB RAM. [my.cnf source](https://github.com/VirtuBox/ubuntu-nginx-web-server/blob/master/etc/mysql/my.cnf)

```bash
cp -f $HOME/ubuntu-nginx-web-server/etc/mysql/my.cnf /etc/mysql/my.cnf
```

It include modification of innodb_log_file_size variable, so you need to use the following commands to apply the new configuration :

```bash
sudo service mysql stop

sudo mv /var/lib/mysql/ib_logfile0 /var/lib/mysql/ib_logfile0.bak
sudo mv /var/lib/mysql/ib_logfile1 /var/lib/mysql/ib_logfile1.bak

sudo service mysql start
```

### Increase MariaDB open files limits

```bash
echo -e '[Service]\nLimitNOFILE=500000' > /etc/systemd/system/mariadb.service.d/limits.conf

sudo systemctl daemon-reload
sudo systemctl restart mariadb
```

### Setup cronjob to optimize your MySQL databases and repair them if needed

Open the crontab editor

```bash
sudo crontab -e
```

Then add the following cronjob

```cronjob
@weekly /usr/bin/mysqlcheck -Aos --auto-repair > /dev/null 2>&1
```

## Install WordOps

```bash
# noninteractive install - you can replace $USER with your username & root@$HOSTNAME by your email
sudo bash -c 'echo -e "[user]\n\tname = $USER\n\temail = root@$HOSTNAME" > $HOME/.gitconfig'

wget -qO wo wops.cc && sudo bash wo
```

### enable wo bash_completion

```bash
source /etc/bash_completion.d/wo_auto.rc
```

### Install Nginx, php7.2, php7.3, and configure WO backend

```bash
wo stack install
wo stack install --php73
```

### Set your email instead of root@localhost

```bash
echo 'root: my.email@address.com' >> /etc/aliases
newaliases
```

### Install Composer - Fix phpmyadmin install issue

<span style="color: red">Included by default in WordOps - this may not be needed anymore</span>

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

## Install PHP

This section has been removed because WordOps already install PHP 7.2 & PHP 7.3 by default

### Set the proper alternative for /usr/bin/php

If you want to choose which version of php to use with the command `php`, you can use the command `update-alternatives`

```bash
# php5.6
sudo update-alternatives --install /usr/bin/php php /usr/bin/php5.6 80

# php7.0
sudo update-alternatives --install /usr/bin/php php /usr/bin/php7.0 80

# php7.1
sudo update-alternatives --install /usr/bin/php php /usr/bin/php7.1 80

# php7.2
sudo update-alternatives --install /usr/bin/php php /usr/bin/php7.2 80

# php7.3
sudo update-alternatives --install /usr/bin/php php /usr/bin/php7.3 80
```

Then you can check php version with command `php -v`

## NGINX Configuration

### Additional Nginx configuration (/etc/nginx/conf.d)

<span style="color: red">Included by default in WordOps - this may not be needed anymore</span>

- stub_status configuration on 127.0.0.1:80 : stub_status.conf
- restore visitor real IP under Cloudflare : cloudflare.conf

```bash
# copy all common nginx configurations
cp -rf $HOME/ubuntu-nginx-web-server/etc/nginx/conf.d/* /etc/nginx/conf.d/

# commit change with git
[ ! -d /etc/nginx/.git ] && { git -C /etc/nginx init; } git -C /etc/nginx/ add . && git -C /etc/nginx/ commit -m "update conf.d configurations"
```

### Compile the latest Nginx release with [nginx-ee](https://github.com/VirtuBox/nginx-ee)

```bash
bash <(wget -O - virtubox.net/nginx-ee || curl -sL virtubox.net/nginx-ee)
```

--------------------------------------------------------------------------------

## Custom configurations

### Nginx optimized configurations

Choose one of them

```bash
# TLSv1.2 TLSv1.3 only (recommended)
cp -f $HOME/ubuntu-nginx-web-server/etc/nginx/nginx.conf /etc/nginx/nginx.conf

# TLSv1.2 only
cp -f $HOME/ubuntu-nginx-web-server/etc/nginx/nginx.conf /etc/nginx/nginx-tlsv12.conf
```

```bash
# commit change with git
[ ! -d /etc/nginx/.git ] && { git -C /etc/nginx init; } git -C /etc/nginx/ add . && git -C /etc/nginx/ commit -m "update nginx.conf"
```

### Nginx configuration for netdata

<span style="color: red">Included by default in WordOps - this may not be needed anymore</span>

```bash
# add nginx reverse-proxy for netdata on https://yourserver.hostname:22222/netdata/
cp -f $HOME/ubuntu-nginx-web-server/etc/nginx/sites-available/22222 /etc/nginx/sites-available/22222

# commit change with git
[ ! -d /etc/nginx/.git ] && { git -C /etc/nginx init; } git -C /etc/nginx/ add . && git -C /etc/nginx/ commit -m "update 22222 configuration"
```

#### Increase Nginx open files limits

```bash
sudo mkdir -p /etc/systemd/system/nginx.service.d
echo -e '[Service]\nLimitNOFILE=500000' > /etc/systemd/system/nginx.service.d/limits.conf

sudo systemctl daemon-reload
sudo systemctl restart nginx.service
```

--------------------------------------------------------------------------------

## Security

### Harden SSH Security

WARNING : SSH Configuration with root login allowed using SSH keys only [source](https://github.com/VirtuBox/ubuntu-nginx-web-server/blob/master/etc/ssh/sshd_config)

```bash
cp -f $HOME/ubuntu-nginx-web-server/etc/ssh/sshd_config /etc/ssh/sshd_config
```

### UFW

Instructions available in [VirtuBox Knowledgebase](https://kb.virtubox.net/knowledgebase/ufw-iptables-firewall-configuration-made-easier/)

```bash
# enable ufw log - allow outgoing - deny incoming
ufw logging low
ufw default allow outgoing
ufw default deny incoming

# allow incoming traffic on SSH port
CURRENT_SSH_PORT=$(grep "Port" /etc/ssh/sshd_config | awk -F " " '{print $2}')
ufw allow $CURRENT_SSH_PORT

# DNS - HTTP/S - FTP - NTP - RSYNC - DHCP - EE Backend
ufw allow 53
ufw allow http
ufw allow https
ufw allow 21
ufw allow 123
ufw allow 68
ufw allow 546
ufw allow 873
ufw allow 22222


# enable UFW
echo "y" | ufw enable
```

### Custom jails for fail2ban

- wordpress bruteforce
- ssh
- recidive (after 3 bans)
- backend http auth
- nginx bad bots

```bash
cp -rf $HOME/ubuntu-nginx-web-server/etc/fail2ban/filter.d/* /etc/fail2ban/filter.d/
cp -rf $HOME/ubuntu-nginx-web-server/etc/fail2ban/jail.d/* /etc/fail2ban/jail.d/

fail2ban-client reload
```

### Secure Memcached server

```bash
echo '-U 0' >> /etc/memcached.conf
sudo systemctl restart memcached
```

If you do not use memcached, you can safely stop it and disable it :

```bash
sudo systemctl stop memcached
sudo systemctl disable memcached.service
```

--------------------------------------------------------------------------------

## Optional

### proftpd

#### Install proftpd

```bash
apt-get install proftpd -y
```

secure proftpd and enable passive ports

```bash
sed -i 's/# DefaultRoot/DefaultRoot/' /etc/proftpd/proftpd.conf
sed -i 's/# RequireValidShell/RequireValidShell/' /etc/proftpd/proftpd.conf
sed -i 's/# PassivePorts                  49152 65534/PassivePorts                  49000 50000/' /etc/proftpd/proftpd.conf
```

restart proftpd

```bash
sudo service proftpd restart
```

Allow FTP ports with UFW

```bash
# ftp active port
sudo ufw allow 21

# ftp passive ports
sudo ufw allow 49000:50000/tcp
```

Enable fail2ban proftpd jail

```bash
echo -e '\n[proftpd]\nenabled = true\n' >> /etc/fail2ban/jail.d/custom.conf

fail2ban-client reload
```

#### Adding FTP users

```bash
# create user without shell access in group www-data
adduser --home /var/www/yourdomain.tld/ --shell /bin/false --ingroup www-data youruser

# allow group read/write on website folder
chmod -R g+rw /var/www/yourdomain.tld
```

--------------------------------------------------------------------------------

### ee-acme-sh

<span style="color: red">Included by default in WordOps - this may not be needed anymore</span>

[Github repository](https://virtubox.github.io/ee-acme-sh/) - Script to setup letsencrypt certificates using acme.sh on EasyEngine servers

- subdomain support
- ivp6 support
- wildcards certificates support

```bash
wget-qO install-ee-acme.sh https://raw.githubusercontent.com/VirtuBox/ee-acme-sh/master/install.sh
chmod +x install-ee-acme.sh
./install-ee-acme.sh

# enable acme.sh & ee-acme-sh
source .bashrc
```

--------------------------------------------------------------------------------

### netdata

<span style="color: red">Included by default in WordOps - this may not be needed anymore</span>

[Github repository](https://github.com/firehol/netdata)

```bash
# save 40-60% of netdata memory
echo 1 >/sys/kernel/mm/ksm/run
echo 1000 >/sys/kernel/mm/ksm/sleep_millisecs

# install netdata
bash <(curl -Ss https://my-netdata.io/kickstart.sh) all --dont-wait

# increase open files limits for netdata
sudo mkdir -p /etc/systemd/system/netdata.service.d
echo -e '[Service]\nLimitNOFILE=500000' > /etc/systemd/system/netdata.service.d/limits.conf

sudo systemctl daemon-reload
sudo systemctl restart netdata.service

# disable email notifications
sudo sed -i 's/SEND_EMAIL="YES"/SEND_EMAIL="NO"/' /usr/lib/netdata/conf.d/health_alarm_notify.conf
service netdata restart
```

--------------------------------------------------------------------------------

### cht.sh (cheat)

[Github repository](https://github.com/chubin/cheat.sh)

```bash
curl https://cht.sh/:cht.sh > /usr/bin/cht.sh
chmod +x /usr/bin/cht.sh


echo "alias cheat='cht.sh'" >> $HOME/.bashrc
source $HOME/.bashrc
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

--------------------------------------------------------------------------------

### nanorc - Improved Nano Syntax Highlighting Files

[Github repository](https://github.com/scopatz/nanorc)

```bash
wget https://raw.githubusercontent.com/scopatz/nanorc/master/install.sh -qO- | sh
```

--------------------------------------------------------------------------------

### Add WP-CLI & bash-completion for user www-data

<span style="color: red">Included by default in WordOps - this may not be needed anymore</span>

```bashrc
# download wp-cli bash_completion
wget -qO /etc/bash_completion.d/wp-completion.bash https://raw.githubusercontent.com/wp-cli/wp-cli/master/utils/wp-completion.bash

# change /var/www owner
chown www-data:www-data /var/www

# download .profile & .bashrc for www-data
cp -f $HOME/ubuntu-nginx-web-server/var/www/.* /var/www/

# set owner
chown www-data:www-data /var/www/{.profile,.bashrc}
```

## Cleanup previous EasyEngine v3

<span style="color: red">Included by default in WordOps - this may not be needed anymore</span>

EasyEngine migration to WordOps is now handled by the install script. The only step to finish the migration is to remove previous php versions if you don't need them anymore.

### Removing previous php versions

```bash
# php5.6
apt-get -y autoremove php5.6-fpm php5.6-common --purge

# php7.0
apt-get -y autoremove php7.0-fpm php7.0-common --purge
```

Published & maintained by [VirtuBox](https://virtubox.net)
