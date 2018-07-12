#!/bin/bash

# automated EasyEngine server configuration script
# dev currently in progress, not ready to be used

CSI="\\033["
CEND="${CSI}0m"
CRED="${CSI}1;31m"
CGREEN="${CSI}1;32m"



# Check if user is root
if [ "$(id -u)" != "0" ]; then
    echo "Error: You must be root to run this script, please use the root user to install the software."
    exit 1
fi

clear

# additionals modules choice

echo ""
echo "Welcome to ubuntu-nginx-web-server install script."
echo ""

#####
# Update packages
#####

sudo apt-get update
sudo apt-get upgrade -y && apt-get autoremove -y && apt-get clean

#####
# UFW
#####

if [ ! -d /etc/ufw ];
then
  apt-get install ufw -y
fi

ufw logging low
ufw default allow outgoing
ufw default deny incoming

# required
ufw allow 22
ufw allow 53
ufw allow http
ufw allow https
ufw allow 21
ufw allow 68
ufw allow 546
ufw allow 873
ufw allow 123
ufw allow 22222


# optional for monitoring

ufw allow 161
ufw allow 6556
ufw allow 10050

# ftp passive ports

ufw allow 49000:50000/tcp


#ufw enable

#####
# Useful packages
#####

sudo apt-get install haveged curl git unzip zip fail2ban htop nload nmon ntp -y

#####
# ntp time
#####

sudo systemctl enable ntp

#####
# Sysctl tweaks +  open_files limits
#####

sudo modprobe tcp_htcp
wget -O /etc/sysctl.conf https://virtubox.github.io/ubuntu-nginx-web-server/files/etc/sysctl.conf
sysctl -p
wget -O /etc/security/limits.conf https://virtubox.github.io/ubuntu-nginx-web-server/files/etc/security/limits.conf

#####
# Redis transparent_hugepage
#####

echo never > /sys/kernel/mm/transparent_hugepage/enabled

#####
# Add MariaDB 10.3 repository
#####

curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup \
| sudo bash -s -- --mariadb-server-version=10.3 --skip-maxscale -y
sudo apt-get update

#####
# MariaDB 10.3 install
#####

#ROOT_SQL_PASS=""
#export DEBIAN_FRONTEND=noninteractive
#sudo debconf-set-selections <<< 'mariadb-server-10.3 mysql-server/root_password password $ROOT_SQL_PASS'
#sudo debconf-set-selections <<< 'mariadb-server-10.3 mysql-server/root_password_again password $ROOT_SQL_PASS'
sudo apt-get install -y mariadb-server



#cat <<EOF >~/.my.cnf
# [client]
# user= root
# password= $ROOT_SQL_PASS
#EOF
#cp ~/.my.cnf /etc/mysql/conf.d/my.cnf

#####
# MariaDB tweaks
#####

wget -O /etc/mysql/my.cnf https://virtubox.github.io/ubuntu-nginx-web-server/files/etc/mysql/my.cnf

sudo service mysql stop

sudo mv /var/lib/mysql/ib_logfile0 /var/lib/mysql/ib_logfile0.bak
sudo mv /var/lib/mysql/ib_logfile1 /var/lib/mysql/ib_logfile1.bak

wget -O /etc/systemd/system/mariadb.service.d/limits.conf https://virtubox.github.io/ubuntu-nginx-web-server/files/etc/systemd/system/mariadb.service.d/limits.conf
sudo systemctl daemon-reload

sudo service mysql start

#####
# EasyEngine automated install
#####

sudo bash -c 'echo -e "[user]\n\tname = $USER\n\temail = $USER@$HOSTNAME" > $HOME/.gitconfig'
sudo wget -qO ee rt.cx/ee && sudo bash ee

source /etc/bash_completion.d/ee_auto.rc

#####
# EasyEngine stacks install
#####

ee stack install
ee stack install --php7 --redis --admin --phpredisadmin


#####
# Fix phpmyadmin install
#####

cd ~/ ||exit
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/bin/composer
sudo -u www-data composer update -d /var/www/22222/htdocs/db/pma/

#####
# Allow www-data shell access for SFTP + add .bashrc settings et completion
#####

usermod -s /bin/bash www-data
chown www-data:www-data /var/www

wget -O /etc/bash_completion.d/wp-completion.bash https://raw.githubusercontent.com/wp-cli/wp-cli/master/utils/wp-completion.bash
wget -O /var/www/.profile https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/docs/files/var/www/.profile
wget -O /var/www/.bashrc https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/docs/files/var/www/.bashrc

chown www-data:www-data /var/www/.profile
chown www-data:www-data /var/www/.bashrc

#####
# Install php7.1-fpm
#####

sudo apt-get install php7.1-fpm php7.1-cli php7.1-zip php7.1-opcache php7.1-mysql php7.1-mcrypt php7.1-mbstring php7.1-json php7.1-intl \
php7.1-gd php7.1-curl php7.1-bz2 php7.1-xml php7.1-tidy php7.1-soap php7.1-bcmath -y php7.1-xsl

sudo wget -O /etc/php/7.1/fpm/pool.d/www.conf https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/php/7.1/fpm/pool.d/www.conf

sudo wget -O /etc/php/7.1/fpm/php.ini https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/php/7.1/fpm/php.ini

sudo service php7.1-fpm restart

#####
# Install php7.2-fpm
#####

sudo apt-get install php7.2-fpm php7.2-xml php7.2-bz2  php7.2-zip php7.2-mysql  php7.2-intl php7.2-gd php7.2-curl php7.2-soap php7.2-mbstring -y

#wget -O /etc/php/7.2/fpm/pool.d/www.conf https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/php/7.2/fpm/pool.d/www.conf
#service php7.2-fpm restart

bash <(wget -O - https://raw.githubusercontent.com/VirtuBox/nginx-ee/master/nginx-build.sh)

wget -O /etc/nginx/conf.d/upstream.conf https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/nginx/conf.d/upstream.conf
service nginx reload

cd /etc/nginx/common || exit
wget https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/common.zip
unzip common.zip

wget -O /etc/php/7.0/cli/php.ini https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/php/7.0/cli/php.ini
wget -O /etc/php/7.0/fpm/php.ini https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/php/7.0/fpm/php.ini

wget -O /etc/fail2ban/filter.d/ddos.conf https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/fail2ban/filter.d/ddos.conf
wget -O /etc/fail2ban/filter.d/ee-wordpress.conf https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/fail2ban/filter.d/ee-wordpress.conf
wget -O /etc/fail2ban/jail.d/custom.conf https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/fail2ban/jail.d/custom.conf
wget -O  /etc/fail2ban/jail.d/ddos.conf https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/fail2ban/jail.d/ddos.conf

fail2ban-client reload

wget -O /etc/nginx/nginx.conf https://virtubox.github.io/ubuntu-nginx-web-server/files/etc/nginx/nginx.conf

wget -O /etc/nginx/sites-available/default  https://virtubox.github.io/ubuntu-nginx-web-server/files/etc/nginx/sites-available/default

# add netdata, php7.1 and php7.2 upstream
wget -O /etc/nginx/conf.d/upstream.conf https://virtubox.github.io/ubuntu-nginx-web-server/files/etc/nginx/conf.d/upstream.conf

# add nginx reverse-proxy for netdata on https://yourserver.hostname:22222/netdata/
wget -O /etc/nginx/sites-available/22222 https://virtubox.github.io/ubuntu-nginx-web-server/files/etc/nginx/sites-available/22222

# 1) add webp mapping
wget -O /etc/nginx/conf.d/webp.conf  https://virtubox.github.io/ubuntu-nginx-web-server/files/etc/nginx/conf.d/webp.conf

# 2) wpcommon files
# php7
wget -O /etc/nginx/common/wpcommon-php7.conf https://virtubox.github.io/ubuntu-nginx-web-server/files/etc/nginx/common/wpcommon-php7.conf

# php7.1
wget -O /etc/nginx/common/wpcommon-php71.conf https://virtubox.github.io/ubuntu-nginx-web-server/files/etc/nginx/common/wpcommon-php71.conf

# php7.2
wget -O /etc/nginx/common/wpcommon-php72.conf https://virtubox.github.io/ubuntu-nginx-web-server/files/etc/nginx/common/wpcommon-php72.conf

nginx -t
service nginx reload

wget https://raw.githubusercontent.com/scopatz/nanorc/master/install.sh -O- | sh

sudo add-apt-repository ppa:utappia/stable -y
sudo
sudo apt install ucaresystem-core -y


# ProFTPd

sudo apt install proftpd -y

sed -i 's/# DefaultRoot/DefaultRoot/' /etc/proftpd/proftpd.conf
sed -i 's/# RequireValidShell/RequireValidShell/' /etc/proftpd/proftpd.conf
sed -i 's/# PassivePorts                  49152 65534/PassivePorts                  49000 50000/' /etc/proftpd/proftpd.conf

sudo service proftpd restart

if [ ! -d /etc/netdata ];
then

## install dependencies
sudo apt-get install autoconf autoconf-archive autogen automake gcc libmnl-dev lm-sensors make nodejs pkg-config python python-mysqldb python-psycopg2 python-pymongo python-yaml uuid-dev zlib1g-dev -y

## install nedata
bash <(curl -Ss https://my-netdata.io/kickstart.sh) all --dont-wait

## optimize netdata resources usage
echo 1 >/sys/kernel/mm/ksm/run
echo 1000 >/sys/kernel/mm/ksm/sleep_millisecs

## disable email notifications
sed -i 's/SEND_EMAIL="YES"/SEND_EMAIL="NO"/' /etc/netdata/health_alarm_notify.conf
service netdata restart

fi

# nginx configuration setup

# check nginx configuration
CONF_22222=$(cat /etc/nginx/sites-available/22222 | grep netdata | wc -l)
CONF_UPSTREAM=$(cat /etc/nginx/conf.d/upstream.conf | grep netdata | wc -l  )
CONF_DEFAULT=$(cat /etc/nginx/sites-available/default | grep status | wc -l)

if "$CONF_22222" = 0;
then
sudo wget -O /etc/nginx/sites-available/22222 https://virtubox.github.io/ubuntu-nginx-web-server/files/etc/nginx/sites-available/22222
fi

if "$CONF_UPSTREAM" = 0;
then
sudo wget -O /etc/nginx/conf.d/upstream.conf https://virtubox.github.io/ubuntu-nginx-web-server/files/etc/nginx/conf.d/upstream.conf
fi

if "$CONF_DEFAULT" = 0;
then
sudo wget -O /etc/nginx/sites-available/default  https://virtubox.github.io/ubuntu-nginx-web-server/files/etc/nginx/sites-available/default
fi


# extplorer install if needed

if [ ! -d /var/www/22222/htdocs/files ];
then

mkdir /var/www/22222/htdocs/files
wget http://extplorer.net/attachments/download/74/eXtplorer_2.1.10.zip -O /var/www/22222/htdocs/files/ex.zip
cd /var/www/22222/htdocs/files && unzip ex.zip && rm ex.zip
fi

# easyengine dashboard install/update

cd /var/www/22222 || exit
if [ -f easyengine-dashboard-master.zip ];
then
  sudo rm easyengine-dashboard-master.zip
fi

## download latest version of EasyEngine-dashboard
wget https://codeload.github.com/VirtuBox/easyengine-dashboard/zip/master -O easyengine-dashboard.zip
unzip easyengine-dashboard.zip
sudo cp -rf easyengine-dashboard-master/* /var/www/22222/htdocs/
sudo chown -R www-data:www-data /var/www/22222/htdocs
