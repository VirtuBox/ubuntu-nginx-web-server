# Ubuntu custom configuration with EasyEngine

Custom server configuration with EasyEngine on Ubuntu 16.04 LTS

----

## Initial configuration

**System update and packages cleanup**

```
apt-get update && apt-get upgrade -y && apt-get autoremove -y && apt-get clean
```

**Install useful packages**  
```
sudo apt install haveged curl git unzip zip fail2ban python-pip python-setuptools htop -y
```

**Tweak Kernel sysctl configuration**  
```
wget -O /etc/sysctl.conf https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/sysctl.conf
sysctl -p
echo never > /sys/kernel/mm/transparent_hugepage/enabled
wget -O /etc/security/limits.conf https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/security/limits.conf
```

----

## EasyEngine Setup

**Install MariaDB 10.2**  
 
Follow instructions available in my [KnowledgeBase article](https://kb.virtubox.net/knowledgebase/install-latest-mariadb-release-easyengine/) 

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

**Install Composer - Fix phpmyadmin and wp-cli errors**  
```
bash <(wget --no-check-certificate -O - https://git.virtubox.net/virtubox/debian-config/raw/master/composer.sh)
sudo -u www-data composer update -d /var/www/22222/htdocs/db/pma/
sudo wp --allow-root cli update --nightly
```

**Allow ssh access for www-data for SFTP usage**
```
usermod -s /bin/bash www-data
```

**Compile last Nginx mainline release with [nginx-ee script](https://github.com/VirtuBox/nginx-ee)**  

```
bash <(wget -O - https://raw.githubusercontent.com/VirtuBox/nginx-ee/master/nginx-build.sh)
```
----

## Custom configurations

**php7.0-fpm conf**
```
# PHP 7.0 CLI & FPM
wget -O /etc/php/7.0/cli/php.ini https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/php/7.0/cli/php.ini
wget -O /etc/php/7.0/fpm/php.ini https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/php/7.0/fpm/php.ini
```

**Addtional jails for fail2ban**
```
wget -O /etc/fail2ban/filter.d/ddos.conf https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/fail2ban/filter.d/ddos.conf
wget -O /etc/fail2ban/filter.d/ee-wordpress.conf https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/fail2ban/filter.d/ee-wordpress.conf
wget -O /etc/fail2ban/jail.d/custom.conf https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/fail2ban/jail.d/custom.conf
wget -O  /etc/fail2ban/jail.d/ddos.conf https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/fail2ban/jail.d/ddos.conf

fail2ban-client reload
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
**custom nginx conf**  
```
# custom conf for netdata
wget -O /etc/nginx/sites-available/default  https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/nginx/sites-available/default

# add netdata, php7.1 and php7.2 upstream
wget -O /etc/nginx/conf.d/upstream.conf https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/nginx/conf.d/upstream.conf

# add nginx reverse-proxy for netdata on https://yourserver.hostname:22222/netdata/
wget -O /etc/nginx/sites-available/22222 https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/nginx/sites-available/22222

# new nginx rules for wordpress with DoS attack fix and webp support 
# php7
wget -O /etc/nginx/common/wpcommon-php7.conf https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/nginx/common/wpcommon-php7.conf
# php7.1
wget -O /etc/nginx/common/wpcommon-php71.conf https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/nginx/common/wpcommon-php71.conf

nginx -t
service nginx reload
```
----

## Optional tools

**Install acme.sh v2**  
```
wget -O -  https://get.acme.sh | sh
sudo source ~/.bashrc 
```

**Install netdata monitoring and set custom settings**  
```
bash <(curl -Ss https://my-netdata.io/kickstart.sh) all

# save 40-60% of netdata memory
echo 1 >/sys/kernel/mm/ksm/run
echo 1000 >/sys/kernel/mm/ksm/sleep_millisecs

# disable email notifications
wget -O /etc/netdata/health_alarm_notify.conf https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/netdata/health_alarm_notify.conf

```

**Install cheat**
```
pip install cheat
```
usage : cheat command  
example : 
```
~# cheat cat
# Display the contents of a file
cat /path/to/foo

# Display contents with line numbers
cat -n /path/to/foo

# Display contents with line numbers (blank lines excluded)
cat -b /path/to/foo
```

