
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
sudo apt install haveged curl git unzip zip fail2ban htop -y
```
  
**Tweak Kernel** [sysctl.conf](https://github.com/VirtuBox/ubuntu-nginx-web-server/blob/master/etc/sysctl.conf) &
**Increase open files limits** : [limits.conf](https://github.com/VirtuBox/ubuntu-nginx-web-server/blob/master/etc/security/limits.conf)
```
wget -O /etc/sysctl.conf https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/sysctl.conf
sysctl -p
wget -O /etc/security/limits.conf https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/security/limits.conf
```
**Harden SSH Security** [sshd_config](https://github.com/VirtuBox/ubuntu-nginx-web-server/blob/master/etc/ssh/sshd_config)
```
wget -O /etc/ssh/sshd_config https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/ssh/sshd_config
```

**disable transparent hugepage for redis**
```
echo never > /sys/kernel/mm/transparent_hugepage/enabled
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

**Install php7.1-fpm & php7.2-fpm**    
  
  php7.1-fpm
```bash
apt update && apt install php7.1-fpm php7.1-cli php7.1-zip php7.1-opcache php7.1-mysql php7.1-mcrypt php7.1-mbstring php7.1-json php7.1-intl \
php7.1-gd php7.1-curl php7.1-bz2 php7.1-xml php7.1-tidy php7.1-soap php7.1-bcmath -y

wget -O /etc/php/7.1/fpm/pool.d/www.conf https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/php/7.1/fpm/pool.d/www.conf
service php7.1-fpm restart
```
php7.2-fpm
```
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

**php-fpm conf**
```
# PHP 7.0 
wget -O /etc/php/7.0/fpm/php.ini https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/php/7.0/fpm/php.ini
service php7.0-fpm restart

# PHP 7.1
wget -O /etc/php/7.1/fpm/php.ini https://github.com/VirtuBox/ubuntu-nginx-web-server/blob/master/etc/php/7.1/fpm/php.ini
service php7.1-fpm restart

# PHP 7.2
wget -O /etc/php/7.2/fpm/php.ini https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/php/7.2/fpm/php.ini
service php7.2-fpm restart
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
**nginx configuration for netdata & new upstreams**  
```
# custom conf for netdata metrics (php-fpm & nginx status pages)
wget -O /etc/nginx/sites-available/default  https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/nginx/sites-available/default

# add netdata, php7.1 and php7.2 upstream
wget -O /etc/nginx/conf.d/upstream.conf https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/nginx/conf.d/upstream.conf

# add nginx reverse-proxy for netdata on https://yourserver.hostname:22222/netdata/
wget -O /etc/nginx/sites-available/22222 https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/nginx/sites-available/22222
```

**php7 common configurations for wordpress with webp support harden security**  
```
# add webp mapping 
wget -O /etc/nginx/conf.d/webp.conf  https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/nginx/conf.d/webp.conf

# new wpcommon nginx configuraitons for wordpress with DoS attack fix and webp support 
# php7
wget -O /etc/nginx/common/wpcommon-php7.conf https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/nginx/common/wpcommon-php7.conf
# php7.1
wget -O /etc/nginx/common/wpcommon-php71.conf https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/nginx/common/wpcommon-php71.conf

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
