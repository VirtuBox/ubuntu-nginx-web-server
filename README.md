# Ubuntu web server custom configuration with EasyEngine

This is step by step guide of my initial web server configuration with EasyEngine, on a clean Ubuntu 16.04 LTS installation.
Do not hesitate to share your tips or configurations by opening an issue or with a pull request.

--------

**1) System update and packages cleanup**

```
apt-get update && apt-get upgrade -y && apt-get autoremove -y && apt-get clean
```

**2) Install useful packages**  
```
sudo apt install haveged curl git unzip zip fail2ban python-pip python-setuptools htop -y
```

**3) Tweak Kernel sysctl configuration**  
```
wget -O /etc/sysctl.conf https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/sysctl.conf
sysctl -p
echo never > /sys/kernel/mm/transparent_hugepage/enabled
wget -O /etc/security/limits.conf https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/security/limits.conf
```

**4) Set your email instead of root@localhost**  
```
echo "root: my.email@address.com" >> /etc/aliases
newaliases
```

**5) Install cheat**
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

**5) Install netdata monitoring and set custom settings**  
```
bash <(curl -Ss https://my-netdata.io/kickstart.sh) all

# save 40-60% of netdata memory
echo 1 >/sys/kernel/mm/ksm/run
echo 1000 >/sys/kernel/mm/ksm/sleep_millisecs

# disable email notifications
wget -O /etc/netdata/health_alarm_notify.conf https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/netdata/health_alarm_notify.conf

```


**6) Install MariaDB 10.2**   
Follow instructions available in my [KnowledgeBase article](https://kb.virtubox.net/knowledgebase/install-latest-mariadb-release-easyengine/) 

```
curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup \
| sudo bash -s -- --mariadb-server-version=10.2 --skip-maxscale
sudo apt update
sudo apt install mariadb-server
```

**7) Install EasyEngine**  
```
wget -qO ee rt.cx/ee && bash ee
```
**8) Install Nginx, php5.6, php7.0, postfix, redis and configure EE backend**  
```
ee stack install
ee stack install --php7 --redis --admin --phpredisadmin
```
**9) Set custom conf for php**
```
# PHP 7.0 CLI & FPM
wget -O /etc/php/7.0/cli/php.ini https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/php/7.0/cli/php.ini
wget -O /etc/php/7.0/fpm/php.ini https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/php/7.0/fpm/php.ini
```

**9) Add custom configuration for fail2ban**
```
wget -O /etc/fail2ban/filter.d/ddos.conf https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/fail2ban/filter.d/ddos.conf
wget -O /etc/fail2ban/filter.d/ee-wordpress.conf https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/fail2ban/filter.d/ee-wordpress.conf
wget -O /etc/fail2ban/jail.d/custom.conf https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/fail2ban/jail.d/custom.conf
wget -O  /etc/fail2ban/jail.d/ddos.conf https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/fail2ban/jail.d/ddos.conf

fail2ban-client reload
```

**10) Install Composer - Fix phpmyadmin and wp-cli errors**  
```
bash <(wget --no-check-certificate -O - https://git.virtubox.net/virtubox/debian-config/raw/master/composer.sh)
sudo -u www-data composer update -d /var/www/22222/htdocs/db/pma/
sudo wp --allow-root cli update --nightly
```

**11) Compile last Nginx mainline release with my [nginx-ee bash script](https://github.com/VirtuBox/nginx-ee)**  

```
bash <(wget -O - https://raw.githubusercontent.com/VirtuBox/nginx-ee/master/nginx-build.sh)
```

**12) Apply Nginx optimized configuration**  
```

# TLSv1.2 TLSv1.3 only
wget -O /etc/nginx/nginx.conf https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/nginx/nginx.conf

# Cloudflare compatible
wget -O /etc/nginx/nginx.conf https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/nginx/nginx-cloudflare.conf

# custom conf for netdata
wget -O /etc/nginx/sites-available/default  https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/nginx/sites-available/default

wget -O /etc/nginx/sites-available/22222 https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/nginx/sites-available/22222

nginx -t
service nginx reload
```
**13) Install acme.sh v2**  
```
wget -O -  https://get.acme.sh | sh
sudo source ~/.bashrc 
```

