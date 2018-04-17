
# Ubuntu optimized configuration with EasyEngine
----
## Server Stack :
* Nginx 1.13x
* PHP-FPM 7/7.1/7.2
* MariaDB 10.2
* REDIS 4.0
* Memcached
* Fail2ban 
* Netdata 
* UFW 

----

Configuration files with comments and informations available by following the link **source**

## Initial configuration

**System update and packages cleanup**

```
apt-get update && apt-get upgrade -y && apt-get autoremove -y && apt-get clean
```

**Install useful packages**  
```
sudo apt install haveged curl git unzip zip fail2ban htop -y
```
  
**Tweak Kernel** [source](https://github.com/VirtuBox/ubuntu-nginx-web-server/blob/master/etc/sysctl.conf) &
**Increase open files limits**  [source](https://github.com/VirtuBox/ubuntu-nginx-web-server/blob/master/etc/security/limits.conf)
```
wget -O /etc/sysctl.conf https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/sysctl.conf
sysctl -p
wget -O /etc/security/limits.conf https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/security/limits.conf
```
**disable transparent hugepage for redis**
```
echo never > /sys/kernel/mm/transparent_hugepage/enabled
```

## Security 
----

**Harden SSH Security**  
WARNING : SSH Configuration with root login allowed with ed25519 & ECDSA SSH keys only  [source](https://github.com/VirtuBox/ubuntu-nginx-web-server/blob/master/etc/ssh/sshd_config)
```
wget -O /etc/ssh/sshd_config https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/ssh/sshd_config
```

**Custom jails for fail2ban**

* wordpress bruteforce
* ssh 
* recidive (after 3 bans)
* backend http auth 
* nginx bad bots 

```
wget -O /etc/fail2ban/filter.d/ddos.conf https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/fail2ban/filter.d/ddos.conf
wget -O /etc/fail2ban/filter.d/ee-wordpress.conf https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/fail2ban/filter.d/ee-wordpress.conf
wget -O /etc/fail2ban/jail.d/custom.conf https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/fail2ban/jail.d/custom.conf
wget -O  /etc/fail2ban/jail.d/ddos.conf https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/fail2ban/jail.d/ddos.conf

fail2ban-client reload
```

**UFW** Instructions available in [VirtuBox Knowledgebase](https://kb.virtubox.net/knowledgebase/ufw-iptables-firewall-configuration-made-easier/)

```
# enable ufw log - allow outgoing - deny incoming 
ufw logging on
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


----

## EasyEngine Setup

**Install MariaDB 10.2** Instructions available in   [VirtuBox Knowledgebase](https://kb.virtubox.net/knowledgebase/install-latest-mariadb-release-easyengine/) 

```
curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup \
| sudo bash -s -- --mariadb-server-version=10.2 --skip-maxscale
sudo apt update
sudo apt install mariadb-server
```

**Install EasyEngine**  
```
wget -qO ee rt.cx/ee && bash ee
```
**Install Nginx, php5.6, php7.0, postfix, redis and configure EE backend**  
```
ee stack install
ee stack install --php7 --redis --admin --phpredisadmin
```

**Set your email instead of root@localhost**  
```
echo 'root: my.email@address.com' >> /etc/aliases
newaliases
```

**Install Composer - Fix phpmyadmin install issue**  
```
cd ~/
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/bin/composer
sudo -u www-data composer update -d /var/www/22222/htdocs/db/pma/
```

**Allow shell for www-data for SFTP usage**
```
usermod -s /bin/bash www-data
```

## PHP 7.1 & 7.2 Setup 

**Install php7.1-fpm & php7.2-fpm**    
  

```bash
# php7.1-fpm
apt update && apt install php7.1-fpm php7.1-cli php7.1-zip php7.1-opcache php7.1-mysql php7.1-mcrypt php7.1-mbstring php7.1-json php7.1-intl \
php7.1-gd php7.1-curl php7.1-bz2 php7.1-xml php7.1-tidy php7.1-soap php7.1-bcmath -y php7.1-xsl

wget -O /etc/php/7.1/fpm/pool.d/www.conf https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/php/7.1/fpm/pool.d/www.conf
service php7.1-fpm restart

# php7.2-fpm
apt update && apt install php7.2-fpm php7.2-xml php7.2-bz2  php7.2-zip php7.2-mysql  php7.2-intl php7.2-gd php7.2-curl php7.2-soap php7.2-mbstring -y

wget -O /etc/php/7.2/fpm/pool.d/www.conf https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/php/7.2/fpm/pool.d/www.conf
service php7.2-fpm restart
```
add nginx upstreams
```
wget -O /etc/nginx/conf.d/upstream.conf https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/nginx/conf.d/upstream.conf
service nginx reload
```
add ee common configuration 
```
cd /etc/nginx/common || exit
wget https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/common.zip
unzip common.zip
```
**Compile last Nginx mainline release with [nginx-ee script](https://github.com/VirtuBox/nginx-ee)**  

```
bash <(wget -O - https://raw.githubusercontent.com/VirtuBox/nginx-ee/master/nginx-build.sh)
```
----

## Custom configurations

**clean php-fpm php.ini configurations**
```
# PHP 7.0 
wget -O /etc/php/7.0/fpm/php.ini https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/php/7.0/fpm/php.ini
service php7.0-fpm restart

# PHP 7.1
wget -O /etc/php/7.1/fpm/php.ini https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/php/7.1/fpm/php.ini
service php7.1-fpm restart

# PHP 7.2
wget -O /etc/php/7.2/fpm/php.ini https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/php/7.2/fpm/php.ini
service php7.2-fpm restart
```


**Nginx optimized configurations**  
```

# TLSv1.2 TLSv1.3 only
wget -O /etc/nginx/nginx.conf https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/nginx/nginx.conf

# TLS intermediate
wget -O /etc/nginx/nginx.conf https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/nginx/nginx-intermediate.conf

# TLSv1.2 only
wget -O /etc/nginx/nginx.conf https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/nginx/nginx-tlsv12.conf

```
**nginx configuration for netdata & new upstreams**  
```
# custom conf for netdata metrics (php-fpm & nginx status pages)
wget -O /etc/nginx/sites-available/default  https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/nginx/sites-available/default

# add netdata, php7.1 and php7.2 upstream
wget -O /etc/nginx/conf.d/upstream.conf https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/nginx/conf.d/upstream.conf

# add nginx reverse-proxy for netdata on https://yourserver.hostname:22222/netdata/
wget -O /etc/nginx/sites-available/22222 https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/nginx/sites-available/22222
```

**wpcommon-php7x configurations**  
* webp rewrite rules added
* DoS attack CVE fix added
* php7.1 & php7.2 configuration added

```
# 1) add webp mapping 
wget -O /etc/nginx/conf.d/webp.conf  https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/nginx/conf.d/webp.conf

# 2) wpcommon files 

# php7
wget -O /etc/nginx/common/wpcommon-php7.conf https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/nginx/common/wpcommon-php7.conf

# php7.1
wget -O /etc/nginx/common/wpcommon-php71.conf https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/nginx/common/wpcommon-php71.conf

# php7.2
wget -O /etc/nginx/common/wpcommon-php72.conf https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/nginx/common/wpcommon-php72.conf

nginx -t
service nginx reload
```
----

## Optional tools

### Acme.sh 
[Github repository](https://github.com/Neilpang/acme.sh) 
```
wget -O -  https://get.acme.sh | sh
source ~/.bashrc 
```

### netdata 
[Github repository](https://github.com/firehol/netdata)
```
bash <(curl -Ss https://my-netdata.io/kickstart.sh) all

# save 40-60% of netdata memory
echo 1 >/sys/kernel/mm/ksm/run
echo 1000 >/sys/kernel/mm/ksm/sleep_millisecs

# disable email notifications
wget -O /etc/netdata/health_alarm_notify.conf https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/netdata/health_alarm_notify.conf

```

### bash-snippets
[Github repository](https://github.com/alexanderepstein/Bash-Snippets)
```bash 
sudo add-apt-repository ppa:navanchauhan/bash-snippets
sudo apt update
sudo apt install bash-snippets
```
usage : cheat command  

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

Published & maintained by [VirtuBox](https://virtubox.net)