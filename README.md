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
```

**4) Set your email instead of root@localhost**
```
echo "root: my.email@address.com" >> /etc/aliases
newaliases
```

**5) Install netdata monitoring**
```
bash <(curl -Ss https://my-netdata.io/kickstart-static64.sh) all
```

**6) Install MariaDB 10.2** <br>
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
**7) Install Nginx, php5.6, php7.0, postfix, redis and configure EE backend **
```
ee stack install
ee stack install --php7 --redis --admin --phpredisadmin
```

**8) Install Composer - Fix phpmyadmin and wp-cli errors**
```
bash <(wget --no-check-certificate -O - https://git.virtubox.net/virtubox/debian-config/raw/master/composer.sh)
sudo -u www-data composer update -d /var/www/22222/htdocs/db/pma/
sudo wp --allow-root cli update --nightly
```

**9) Compile last Nginx mainline release with my [nginx-ee bash script](https://github.com/VirtuBox/nginx-ee)**

```
bash <(wget -O - https://raw.githubusercontent.com/VirtuBox/nginx-ee/master/nginx-build.sh)
```



