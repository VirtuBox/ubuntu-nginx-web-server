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
sudo apt install haveged curl git unzip zip fail2ban htop -y
```

**3) Tweak Kernel sysctl configuration**  
```
sysctl -e -p <(curl -Ss https://git.virtubox.net/virtubox/debian-config/raw/master/etc/sysctl.conf)
echo never > /sys/kernel/mm/transparent_hugepage/enabled
wget -O /etc/security/limits.conf https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/security/limits.conf
```

**4) Set your email instead of root@localhost**  
```
echo "root: my.email@address.com" >> /etc/aliases
newaliases
```

**5) Install netdata monitoring**  
```
bash <(curl -Ss https://my-netdata.io/kickstart.sh) all
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

**9) Install Composer - Fix phpmyadmin and wp-cli errors**  
```
bash <(wget --no-check-certificate -O - https://git.virtubox.net/virtubox/debian-config/raw/master/composer.sh)
sudo -u www-data composer update -d /var/www/22222/htdocs/db/pma/
sudo wp --allow-root cli update --nightly
```

**10) Compile last Nginx mainline release with my [nginx-ee bash script](https://github.com/VirtuBox/nginx-ee)**  

```
bash <(wget -O - https://raw.githubusercontent.com/VirtuBox/nginx-ee/master/nginx-build.sh)
```

**11) Apply Nginx optimized configuration**  
```
wget -O /etc/nginx/nginx.conf https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/nginx/nginx.conf
wget -O /etc/nginx/sites-available/default  https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/nginx/sites-available/default
wget -O /etc/nginx/sites-available/22222 https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/nginx/sites-available/22222
nginx -t
service nginx reload
```

**12) Install acme.sh v2**  
```
wget -O -  https://get.acme.sh | sh
```
Or 
```
apt-get install openssl cron  netcat-openbsd  curl
mkdir -p /etc/letsencrypt/acme.sh/certs
git clone https://github.com/Neilpang/acme.sh.git
cd acme.sh
./acme.sh --install  \
--home ~/.acme.sh \
--certhome  /etc/letsencrypt/acme.sh/certs \
--accountemail  "hi@acme.sh" \
```

**13) Issue a SSL certificate with Cloudflare API**  
Set your email and API key settings
```
export CF_Key="sdfsdfsdfljlbjkljlkjsdfoiwje"
export CF_Email="hi@acme.sh"
```
Issue a cert
```
# domain
acme.sh  --issue  -d example.com  --dns dns_cf
# domain + www
acme.sh  --issue  -d example.com  --dns dns_cf  -d www.example.com -d dev.example.com
# SAN mode
acme.sh  --issue  -d example.com  --dns dns_cf  -d www.example.com -d dev.example.com
```





