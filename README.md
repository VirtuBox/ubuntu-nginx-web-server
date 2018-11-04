# Optimized configuration for Ubuntu server with EasyEngine

## Server Stack

- Ubuntu 16.04/18.04 LTS
- Nginx 1.15.x / 1.14.x
- PHP-FPM 7/7.1/7.2
- MariaDB 10.3
- REDIS 4.0
- Memcached
- Fail2ban
- Netdata
- UFW

* * *

**Ubuntu-Nginx-web-server is now available (in beta) as bash script to automate Optimized EasyEngine Setup. Checkout [EE-NGINX-SETUP](https://github.com/VirtuBox/ee-nginx-setup)**

* * *

Configuration files with comments available by following the link **source**

## Initial configuration

### System update and packages cleanup

```bash
apt-get update && apt-get upgrade -y && apt-get autoremove --purge -y && apt-get clean
```

### Install useful packages

```bash
sudo apt-get install haveged curl git unzip zip fail2ban htop nload nmon ntp gnupg gnupg2 wget pigz tree ccze mycli -y
```

### Clone the repository

```bash
git clone https://github.com/VirtuBox/ubuntu-nginx-web-server.git $HOME/ubuntu-nginx-web-server
```

### Tweak Kernel & Increase open files limits

[source sysctl.conf](https://github.com/VirtuBox/ubuntu-nginx-web-server/blob/master/etc/sysctl.conf) - [limits.conf source](https://github.com/VirtuBox/ubuntu-nginx-web-server/blob/master/etc/security/limits.conf)

```bash
cp $HOME/ubuntu-nginx-web-server/etc/sysctl.d/60-ubuntu-nginx-web-server.conf /etc/sysctl.d/60-ubuntu-nginx-web-server.conf
```

Ubuntu 16.04 LTS do not support the new tcp congestion control algorithm bbr, we will use htcp instead.

```bash
# On ubuntu 18.04 LTS
modprobe tcp_bbr
echo -e '\nnet.ipv4.tcp_congestion_control = bbr\nnet.ipv4.tcp_notsent_lowat = 16384' >> /etc/sysctl.d/60-ubuntu-nginx-web-server.conf

# On ubuntu 16.04 LTS
modprobe tcp_htcp
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

* * *

## EasyEngine Setup

### Install MariaDB 10.3

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

# copy php-fpm pools & php.ini configuration
cp -rf $HOME/ubuntu-nginx-web-server/etc/php/7.1/fpm/* /etc/php/7.1/fpm/
service php7.1-fpm restart

git -C /etc/php/ add /etc/php/ && git -C /etc/php/ commit -m "add php7.1 configuration"

```

### Install php7.2-fpm

```bash
# php7.2-fpm
apt update && apt install php7.2-fpm php7.2-xml php7.2-bz2 php7.2-zip php7.2-mysql php7.2-intl php7.2-gd php7.2-curl php7.2-soap php7.2-mbstring php7.2-bcmath -y

# copy php-fpm pools & php.ini configuration
cp -rf $HOME/ubuntu-nginx-web-server/etc/php/7.2/fpm/* /etc/php/7.2/fpm/
service php7.2-fpm restart

git -C /etc/php/ add /etc/php/ && git -C /etc/php/ commit -m "add php7.2 configuration"

```

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
```

Then you can check php version with command `php -v`

## NGINX Configuration

### Additional Nginx configuration (/etc/nginx/conf.d)

- New upstreams (php7.1, php7.2, netdata) : upstream.conf
- webp image mapping : webp.conf
- new fastcgi_cache_bypass mapping for wordpress : map-wp-fastcgi-cache.conf
- stub_status configuration on 127.0.0.1:80 : stub_status.conf
- restore visitor real IP under Cloudflare : cloudflare.conf
- mitigate WordPress DoS attack

```bash
# copy all common nginx configurations
cp -rf $HOME/ubuntu-nginx-web-server/etc/nginx/conf.d/* /etc/nginx/conf.d/

# commit change with git
git -C /etc/nginx/ add /etc/nginx/ && git -C /etc/nginx/ commit -m "update conf.d configurations"
```

### EE common configuration

```bash
cp -rf $HOME/ubuntu-nginx-web-server/etc/nginx/common/* /etc/nginx/common/

# commit change with git
git -C /etc/nginx/ add /etc/nginx/ && git -C /etc/nginx/ commit -m "update common configurations"
```

### Compile last Nginx mainline release with [nginx-ee script](https://github.com/VirtuBox/nginx-ee)

```bash
bash <(wget-qO - https://raw.githubusercontent.com/VirtuBox/nginx-ee/master/nginx-build.sh)
```

* * *

## Custom configurations

### clean php-fpm php.ini configuration

```bash
# PHP 7.0
cp -rf $HOME/ubuntu-nginx-web-server/etc/php/7.0/* /etc/php/7.0/
service php7.0-fpm restart

git -C /etc/php/ add /etc/php/ && git -C /etc/php/ commit -m "add php7.2 configuration"
```

### Nginx optimized configurations

```bash
# TLSv1.2 TLSv1.3 only
cp -f $HOME/ubuntu-nginx-web-server/etc/nginx/nginx.conf /etc/nginx/nginx.conf

# TLS intermediate - TLS v1.0 v1.1 v1.2 v1.3
cp -f $HOME/ubuntu-nginx-web-server/etc/nginx/nginx.conf /etc/nginx/nginx-intermediate.conf

# TLSv1.2 only
cp -f $HOME/ubuntu-nginx-web-server/etc/nginx/nginx.conf /etc/nginx/nginx-tlsv12.conf

# commit change with git
git -C /etc/nginx/ add /etc/nginx/ && git -C /etc/nginx/ commit -m "update nginx.conf configurations"
```

### Nginx configuration for netdata

```bash
# add nginx reverse-proxy for netdata on https://yourserver.hostname:22222/netdata/
cp -f $HOME/ubuntu-nginx-web-server/etc/nginx/sites-available/22222 /etc/nginx/sites-available/22222

# commit change with git
git -C /etc/nginx/ add /etc/nginx/ && git -C /etc/nginx/ commit -m "update 22222 configuration"
```

#### Increase Nginx open files limits

```bash
sudo mkdir -p /etc/systemd/system/nginx.service.d
echo -e '[Service]\nLimitNOFILE=500000' > /etc/systemd/system/nginx.service.d/limits.conf

sudo systemctl daemon-reload
sudo systemctl restart nginx.service
```

* * *

## Security

### Harden SSH Security

WARNING : SSH Configuration with root login allowed using SSH keys only  [source](https://github.com/VirtuBox/ubuntu-nginx-web-server/blob/master/etc/ssh/sshd_config)

    cp -f $HOME/ubuntu-nginx-web-server/etc/ssh/sshd_config /etc/ssh/sshd_config

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

If you do not use memcached, you can safely stop and disable it :

```bash
sudo systemctl stop memcached
sudo systemctl disable memcached.service
```

## Optional

### ee-acme-sh

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

### netdata

[Github repository](https://github.com/firehol/netdata)

```bash

bash <(curl -Ss https://my-netdata.io/kickstart.sh) all

# save 40-60% of netdata memory
echo 1 >/sys/kernel/mm/ksm/run
echo 1000 >/sys/kernel/mm/ksm/sleep_millisecs

# increase open files limits for netdata
sudo mkdir -p /etc/systemd/system/netdata.service.d
echo -e '[Service]\nLimitNOFILE=500000' > /etc/systemd/system/netdata.service.d/limits.conf

sudo systemctl daemon-reload
sudo systemctl restart netdata.service

# disable email notifications
sudo sed -i 's/SEND_EMAIL="YES"/SEND_EMAIL="NO"/' /usr/lib/netdata/conf.d/health_alarm_notify.conf
service netdata restart
```

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

### nanorc - Improved Nano Syntax Highlighting Files

[Github repository](https://github.com/scopatz/nanorc)

```bash
wget https://raw.githubusercontent.com/scopatz/nanorc/master/install.sh -qO- | sh
```

### Add WP-CLI & bash-completion for user www-data

```bashrc
# download wp-cli bash_completion
wget -qO /etc/bash_completion.d/wp-completion.bash https://raw.githubusercontent.com/wp-cli/wp-cli/master/utils/wp-completion.bash

# change /var/www owner
chown www-data:www-data /var/www

# download .profile & .bashrc for www-data
cp -f $HOME/ubuntu-nginx-web-server/var/www/.profile /var/www/.profile
cp -f $HOME/ubuntu-nginx-web-server/var/www/.bashrc /var/www/.bashrc

# set owner
chown www-data:www-data /var/www/{.profile,.bashrc}
```

### Custom Nginx error pages

[Github Repository](https://github.com/alexphelps/server-error-pages)

Installation

```bash
# clone the github repository
sudo -u www-data -H git clone https://github.com/alexphelps/server-error-pages.git /var/www/error
```

Then include this configuration in your nginx vhost by adding the following line

```bash
include common/error_pages.conf;
```

Published & maintained by [VirtuBox](https://virtubox.net)
