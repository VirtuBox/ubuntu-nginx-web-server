#!/bin/bash

# automated EasyEngine server configuration script
# currently in progress, not ready to be used in production yet

CSI="\\033["
CEND="${CSI}0m"
#CRED="${CSI}1;31m"
CGREEN="${CSI}1;32m"

##################################
# Variables
##################################

EXTPLORER_VER="2.1.10"
REPO_PATH=/tmp/ubuntu-nginx-web-server

##################################
# Check if user is root
##################################

if [ "$(id -u)" != "0" ]; then
	echo "Error: You must be root to run this script, please use the root user to install the software."
	echo ""
	echo "Use 'sudo su - root' to login as root"
	exit 1
fi

clear

##################################
# Welcome
##################################

echo ""
echo "Welcome to ubuntu-nginx-web-server install script."
echo ""

##################################
# Menu
##################################

echo ""
echo "Do you want to install MariaDB-server ? (y/n)"
while [[ $mariadb_server_install != "y" && $mariadb_server_install != "n" ]]; do
	read -p "Select an option [y/n]: " mariadb_server_install
done
if [ "$mariadb_server_install" = "n" ]; then
	echo ""
	echo "Do you want to install MariaDB-client for a remote database ? (y/n)"
	while [[ $mariadb_client_install != "y" && $mariadb_client_install != "n" ]]; do
		read -p "Select an option [y/n]: " mariadb_client_install
	done
	echo ""
	echo "What is the IP of your remote database ?"
	read -p "IP : " mariadb_remote_ip
	echo ""
	echo "What is the user of your remote database ?"
	read -p "User : " mariadb_remote_user
	echo ""
	echo "What is the password of your remote database ?"
	read -s -p "password [hidden] : " mariadb_remote_password
fi
if [[ "$mariadb_server_install" == "y" || "$mariadb_client_install" == "y" ]]; then
	echo ""
	echo "What version of MariaDB Client/Server do you want to install, 10.1, 10.2 or 10.3 ?"
	while [[ $mariadb_version_install != "10.1" && $mariadb_version_install != "10.2" && $mariadb_version_install != "10.3" ]]; do
		read -p "Select an option [10.1 / 10.2 / 10.3]: " mariadb_version_install
	done
fi
echo ""
echo "Do you want php7.1-fpm ? (y/n)"
while [[ $phpfpm71_install != "y" && $phpfpm71_install != "n" ]]; do
	read -p "Select an option [y/n]: " phpfpm71_install
done
echo ""
echo "Do you want php7.2-fpm ? (y/n)"
while [[ $phpfpm72_install != "y" && $phpfpm72_install != "n" ]]; do
	read -p "Select an option [y/n]: " phpfpm72_install
done
echo ""
echo "Do you want proftpd ? (y/n)"
while [[ $proftpd_install != "y" && $proftpd_install != "n" ]]; do
	read -p "Select an option [y/n]: " proftpd_install
done
echo ""

##################################
# Update packages
##################################


echo -ne "     Updating packages      [..]\\r"
{
	apt-get update
	apt-get upgrade -y
	apt-get autoremove -y --purge
	apt-get autoclean -y
} >>/tmp/ubuntu-nginx-web-server.log

echo -ne "     Updating packages      [${CGREEN}OK${CEND}]\\r"

##################################
# UFW
##################################
echo ""
echo -ne "     Configuring UFW     [..]\\r"
{
	if [ ! -d /etc/ufw ]; then
		apt-get install ufw -y >>/tmp/ubuntu-nginx-web-server.log
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

	#fw allow 161
	#ufw allow 6556
	#ufw allow 10050

} >>/tmp/ubuntu-nginx-web-server.log

echo -ne "     Configuring UFW      [${CGREEN}OK${CEND}]\\r"

##################################
# Useful packages
##################################

echo -ne "     Installing useful packages     [..]\\r"
{

	apt-get install haveged curl git unzip zip fail2ban htop nload nmon ntp gnupg gnupg2 wget -y

	# ntp time
	systemctl enable ntp

	# increase history size
	export HISTSIZE=10000

} >>/tmp/ubuntu-nginx-web-server.log

echo -ne "     Installing useful packages      [${CGREEN}OK${CEND}]\\r"

##################################
# clone repository
##################################
echo ""
echo -ne "     Cloning ubuntu-nginx-web-server     [..]\\r"
{
	cd /tmp || exit
	rm -rf /tmp/ubuntu-nginx-web-server
	git clone https://github.com/VirtuBox/ubuntu-nginx-web-server.git

} >>/tmp/ubuntu-nginx-web-server.log
echo -ne "     Cloning ubuntu-nginx-web-server     [${CGREEN}OK${CEND}]\\r"

##################################
# Sysctl tweaks +  open_files limits
##################################
echo ""
echo -ne "     Applying kernel tweaks    [..]\\r"
{
	sudo modprobe tcp_htcp
	cp -f $REPO_PATH/etc/sysctl.conf /etc/sysctl.conf
	sysctl -p
	cp -f $REPO_PATH/etc/security/limits.conf /etc/security/limits.conf

	# Redis transparent_hugepage
	echo never >/sys/kernel/mm/transparent_hugepage/enabled

} >>/tmp/ubuntu-nginx-web-server.log 2>&1
echo -ne "     Applying kernel tweaks    [${CGREEN}OK${CEND}]\\r"
##################################
# Add MariaDB 10.3 repository
##################################

if [[ "$mariadb_server_install" == "y" || "$mariadb_client_install" == "y" ]]; then
	echo ""
	echo -ne "     Adding mariadb repository    [..]\\r"
	curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup \
	| sudo bash -s -- --mariadb-server-version=$mariadb_version_install --skip-maxscale -y
	apt-get update >>/tmp/ubuntu-nginx-web-server.log
	echo -ne "     Adding mariadb repository      [${CGREEN}OK${CEND}]\\r"
fi

##################################
# MariaDB 10.3 install
##################################


# if user want to install mariadb_server
#
if [ "$mariadb_server_install" = "y" ]; then
	echo ""
	echo -ne "     Installing MariaDB $mariadb_version_install    [..]\\r"

	MYSQL_ROOT_PASS=$(date +%s | sha256sum | base64 | head -c 32)
	export DEBIAN_FRONTEND=noninteractive # to avoid prompt during installation
	sudo debconf-set-selections <<<"mariadb-server-$mariadb_version_install mysql-server/root_password password $MYSQL_ROOT_PASS"
	sudo debconf-set-selections <<<"mariadb-server-$mariadb_version_install mysql-server/root_password_again password $MYSQL_ROOT_PASS"
	# install mariadb server
	DEBIAN_FRONTEND=noninteractive apt-get install -qq mariadb-server >>/tmp/ubuntu-nginx-web-server.log # -qq implies -y --force-yes
	sudo bash -c 'echo -e "[client]\nuser = root" > $HOME/.my.cnf'
	echo "password = $MYSQL_ROOT_PASS" >>$HOME/.my.cnf
	cp $HOME/.my.cnf /etc/mysql/conf.d/my.cnf

	# set password to the root user and grant privileges
	#Q1="GRANT ALL PRIVILEGES on *.* to 'root'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PASS' WITH GRANT OPTION;"
	#Q2="FLUSH PRIVILEGES;"
	#SQL="${Q1}${Q2}"
	#mysql -uroot -e "$SQL"

	## mysql_secure_installation non-interactive way
	mysql -e "GRANT ALL PRIVILEGES on *.* to 'root'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PASS' WITH GRANT OPTION;"
	# remove anonymous users
	mysql -e "DROP USER ''@'localhost'"
    mysql -e "DROP USER ''@'$(hostname)'"
	# remove test database
	mysql -e "DROP DATABASE test"
	# flush privileges
	mysql -e "FLUSH PRIVILEGES"

	echo -ne "     Installing MariaDB $mariadb_version_install      [${CGREEN}OK${CEND}]\\r"
fi
	##################################
	# MariaDB tweaks
	##################################
if [ "$mariadb_server_install" = "y" ]; then
	echo "Configuring MariaDB tweaks"
	cp -f $REPO_PATH/etc/mysql/my.cnf /etc/mysql/my.cnf

	sudo service mysql stop >>/tmp/ubuntu-nginx-web-server.log

	sudo mv /var/lib/mysql/ib_logfile0 /var/lib/mysql/ib_logfile0.bak
	sudo mv /var/lib/mysql/ib_logfile1 /var/lib/mysql/ib_logfile1.bak

	cp -f $REPO_PATH/etc/systemd/system/mariadb.service.d/limits.conf /etc/systemd/system/mariadb.service.d/limits.conf
	systemctl daemon-reload >>/tmp/ubuntu-nginx-web-server.log

	service mysql start >>/tmp/ubuntu-nginx-web-server.log
fi
if [ "$mariadb_client_install" = "y" ]; then
	echo "installing mariadb-client"
	apt-get install -y mariadb-client >>/tmp/ubuntu-nginx-web-server.log
	echo "[client]" >>$HOME/.my.cnf
	echo "host = $mariadb_remote_ip" >>$HOME/.my.cnf
	echo "port = 3306" >>$HOME/.my.cnf
	echo "password = $mariadb_remote_user" >>$HOME/.my.cnf
	echo "password = $mariadb_remote_password" >>$HOME/.my.cnf
	cp -f $REPO_PATH/etc/mysql/my.cnf /etc/mysql/my.cnf
fi

##################################
# EasyEngine automated install
##################################
echo "installing easyengine"

sudo bash -c 'echo -e "[user]\n\tname = $USER\n\temail = $USER@$HOSTNAME" > $HOME/.gitconfig'
{
	sudo wget -qO ee rt.cx/ee && sudo bash ee

	source /etc/bash_completion.d/ee_auto.rc
} >>/tmp/ubuntu-nginx-web-server.log 2>&1

##################################
# EasyEngine stacks install
##################################

if [ "$mariadb_client_install" = "y" ]; then
sudo sed -i 's/grant-host = localhost/grant-host = \%/' /etc/ee/ee.conf
fi

echo "Installing ee stack"
{
	ee stack install
	ee stack install --php7 --redis --admin --phpredisadmin
} >>/tmp/ubuntu-nginx-web-server.log 2>&1

##################################
# Fix phpmyadmin install
##################################
echo "updating phpmyadmin"
{

	cd ~/ || exit
	curl -sS https://getcomposer.org/installer | php >>/tmp/ubuntu-nginx-web-server.log
	mv composer.phar /usr/bin/composer

	chown www-data:www-data /var/www
	sudo -u www-data -H composer update -d /var/www/22222/htdocs/db/pma/

} >>/tmp/ubuntu-nginx-web-server.log 2>&1

##################################
# Allow www-data shell access for SFTP + add .bashrc settings et completion
##################################
echo "configuring www-data permissions"
{

	usermod -s /bin/bash www-data

	wget -O /etc/bash_completion.d/wp-completion.bash https://raw.githubusercontent.com/wp-cli/wp-cli/master/utils/wp-completion.bash >>/tmp/ubuntu-nginx-web-server.log
	cp -f $REPO_PATH/var/www/.profile /var/www/.profile
	cp -f $REPO_PATH/var/www/.bashrc /var/www/.bashrc

	chown www-data:www-data /var/www/.profile
	chown www-data:www-data /var/www/.bashrc

	sudo -u www-data -H wget https://raw.githubusercontent.com/scopatz/nanorc/files/install.sh -O- | sh

} >>/tmp/ubuntu-nginx-web-server.log

##################################
# Install php7.1-fpm
##################################

if [ "$phpfpm71_install" = "y" ]; then

	echo "installing php7.1-fpm"
	apt-get install php7.1-fpm php7.1-cli php7.1-zip php7.1-opcache php7.1-mysql php7.1-mcrypt php7.1-mbstring php7.1-json php7.1-intl \
		php7.1-gd php7.1-curl php7.1-bz2 php7.1-xml php7.1-tidy php7.1-soap php7.1-bcmath -y php7.1-xsl >>/tmp/ubuntu-nginx-web-server.log

	sudo cp -f $REPO_PATH/etc/php/7.1/* /etc/php/7.1/
	sudo service php7.1-fpm restart

fi

##################################
# Install php7.2-fpm
##################################

if [ "$phpfpm72_install" = "y" ]; then
	echo "installing php7.2-fpm"
	apt-get install php7.2-fpm php7.2-xml php7.2-bz2 php7.2-zip php7.2-mysql php7.2-intl php7.2-gd php7.2-curl php7.2-soap php7.2-mbstring -y >>/tmp/ubuntu-nginx-web-server.log

	cp -f $REPO_PATH/etc/php/7.2/* /etc/php/7.2/
	service php7.2-fpm restart

fi

##################################
# Update php7.0-fpm config
##################################
echo "updating php7.0 configuration"
{

	if [ ! -d /etc/php/7.0 ]; then

		cp -f $REPO_PATH/etc/php/7.0/* /etc/php/7.0/

	fi

} >>/tmp/ubuntu-nginx-web-server.log

##################################
# Compile latest nginx release from source
##################################

wget https://raw.githubusercontent.com/VirtuBox/nginx-ee/master/nginx-build.sh
chmod +x nginx-build.sh
./nginx-build.sh

##################################
# Add nginx additional conf
##################################
echo "optimizing nginx configuration"
{

	# php7.1 & 7.2 common configurations

	cp -rf $REPO_PATH/etc/nginx/common/* /etc/nginx/common/

	# optimized nginx.config
	cp -f $REPO_PATH/etc/nginx/nginx.conf /etc/nginx/nginx.conf

	# check nginx configuration
	CONF_22222=$(grep -c netdata /etc/nginx/sites-available/22222)
	CONF_UPSTREAM=$(grep -c netdata /etc/nginx/conf.d/upstream.conf)
	CONF_DEFAULT=$(grep -c status /etc/nginx/sites-available/default)

	if [ "$CONF_22222" = "0" ]; then
		# add nginx reverse-proxy for netdata on https://yourserver.hostname:22222/netdata/
		sudo cp -f $REPO_PATH/etc/nginx/sites-available/22222 /etc/nginx/sites-available/22222
	fi

	if [ "$CONF_UPSTREAM" = "0" ]; then
		# add netdata, php7.1 and php7.2 upstream
		sudo cp -f $REPO_PATH/etc/nginx/conf.d/upstream.conf /etc/nginx/conf.d/upstream.conf
	fi

	if [ "$CONF_DEFAULT" = "0" ]; then
		# additional nginx locations for monitoring
		sudo cp -f $REPO_PATH/etc/nginx/sites-available/default /etc/nginx/sites-available/default
	fi

	# 1) add webp mapping
	cp -f $REPO_PATH/etc/nginx/conf.d/webp.conf /etc/nginx/conf.d/webp.conf

	nginx -t
	service nginx reload

} >>/tmp/ubuntu-nginx-web-server.log

##################################
# Add fail2ban configurations
##################################
echo "configuring fail2ban"
{

	cp -rf $REPO_PATH/etc/fail2ban/filter.d/* /etc/fail2ban/filter.d/
	cp -f $REPO_PATH/etc/fail2ban/jail.d/* /etc/fail2ban/jail.d/

	fail2ban-client reload

} >>/tmp/ubuntu-nginx-web-server.log

##################################
# Install cheat & nanorc
##################################
echo "installing cheat & nanorc"
{

	curl https://cht.sh/:cht.sh >/usr/bin/cht.sh
	chmod +x /usr/bin/cht.sh

	cd || exit
	echo "alias cheat='cht.sh'" >>.bashrc
	source .bashrc

	wget https://raw.githubusercontent.com/scopatz/nanorc/files/install.sh -O- | sh

} >>/tmp/ubuntu-nginx-web-server.log

##################################
# Install ProFTPd
##################################

if [ "$proftpd_install" = "y" ]; then

	echo "installing proftpd"
	apt-get install proftpd -y >>/tmp/ubuntu-nginx-web-server.log

	# secure proftpd and enable PassivePorts

	sed -i 's/# DefaultRoot/DefaultRoot/' /etc/proftpd/proftpd.conf
	sed -i 's/# RequireValidShell/RequireValidShell/' /etc/proftpd/proftpd.conf
	sed -i 's/# PassivePorts                  49152 65534/PassivePorts                  49000 50000/' /etc/proftpd/proftpd.conf

	sudo service proftpd restart

	if [ -d /etc/ufw ]; then
		# ftp passive ports
		ufw allow 49000:50000/tcp
	fi

fi

##################################
# Install Netdata
##################################

if [ ! -d /etc/netdata ]; then
	echo "installing netdata"
	{
		## install dependencies
		apt-get install autoconf autoconf-archive autogen automake gcc libmnl-dev lm-sensors make nodejs pkg-config python python-mysqldb python-psycopg2 python-pymongo python-yaml uuid-dev zlib1g-dev -y >>/tmp/ubuntu-nginx-web-server.log

		## install nedata
		wget https://my-netdata.io/kickstart.sh >>/tmp/ubuntu-nginx-web-server.log
		chmod +x kickstart.sh
		./kickstart.sh all --dont-wait

		## optimize netdata resources usage
		echo 1 >/sys/kernel/mm/ksm/run
		echo 1000 >/sys/kernel/mm/ksm/sleep_millisecs

		## disable email notifigrep -cions
		sudo sed -i 's/SEND_EMAIL="YES"/SEND_EMAIL="NO"/' /etc/netdata/health_alarm_notify.conf
		sudo service netdata restart
	} >>/tmp/ubuntu-nginx-web-server.log
fi

##################################
# Install EasyEngine Dashboard
##################################

echo "installing easyengine-dashboard"
{
	if [ ! -d /var/www/22222/htdocs/files ]; then

		mkdir /var/www/22222/htdocs/files
		wget http://extplorer.net/attachments/download/74/eXtplorer_$EXTPLORER_VER.zip -O /var/www/22222/htdocs/files/ex.zip
		cd /var/www/22222/htdocs/files || exit 1
		unzip ex.zip
		rm ex.zip
	fi

	cd /var/www/22222 || exit

	## download latest version of EasyEngine-dashboard
	cd /tmp || exit
	git clone https://github.com/VirtuBox/easyengine-dashboard.git
	cp -rf /tmp/easyengine-dashboard/* /var/www/22222/htdocs/
	chown -R www-data:www-data /var/www/22222/htdocs

} >>/tmp/ubuntu-nginx-web-server.log

##################################
# Install Acme.sh
##################################
echo "installing acme.sh"
{

	# install acme.sh if needed
	echo ""
	echo "checking if acme.sh is already installed"
	echo ""
	if [ ! -f $HOME/.acme.sh/acme.sh ]; then
		echo ""

		echo ""
		wget -O - https://get.acme.sh | sh
		cd || exit
		source .bashrc
	fi

} >>/tmp/ubuntu-nginx-web-server.log

##################################
# Secure EasyEngine Dashboard with Acme.sh
##################################

MY_HOSTNAME=$(hostname -f)
MY_IP=$(curl -s v4.vtbox.net)
MY_HOSTNAME_IP=$(dig +short @8.8.8.8 "$MY_HOSTNAME")

if [[ "$MY_IP" == "$MY_HOSTNAME_IP" ]]; then
	echo "securing easyengine backend"
	if [ ! -f /etc/systemd/system/multi-user.target.wants/nginx.service ]; then
		systemctl enable nginx.service >>/tmp/ubuntu-nginx-web-server.log
	fi

	if [ ! -d $HOME/.acme.sh/${MY_HOSTNAME}_ecc ]; then
		$HOME/.acme.sh/acme.sh --issue -d $MY_HOSTNAME --keylength ec-384 --standalone --pre-hook "service nginx stop " --post-hook "service nginx start"
	fi

	if [ -d /etc/letsencrypt/live/$MY_HOSTNAME ]; then
		rm -rf /etc/letsencrypt/live/$MY_HOSTNAME/*
	else
		mkdir -p /etc/letsencrypt/live/$MY_HOSTNAME
	fi

	# install the cert and reload nginx
	$HOME/.acme.sh/acme.sh --install-cert -d ${MY_HOSTNAME} --ecc \
		--cert-file /etc/letsencrypt/live/${MY_HOSTNAME}/cert.pem \
		--key-file /etc/letsencrypt/live/${MY_HOSTNAME}/key.pem \
		--fullchain-file /etc/letsencrypt/live/${MY_HOSTNAME}/fullchain.pem \
		--reloadcmd "systemctl reload nginx.service"

	if [ -f /etc/letsencrypt/live/${MY_HOSTNAME}/fullchain.pem ] && [ -f /etc/letsencrypt/live/${MY_HOSTNAME}/key.pem ]; then
		sed -i "s/ssl_certificate \\/var\\/www\\/22222\\/cert\\/22222.crt;/ssl_certificate \\/etc\\/letsencrypt\\/live\\/${MY_HOSTNAME}\\/fullchain.pem;/" /etc/nginx/sites-available/22222
		sed -i "s/ssl_certificate_key \\/var\\/www\\/22222\\/cert\\/22222.key;/ssl_certificate_key    \\/etc\\/letsencrypt\\/live\\/${MY_HOSTNAME}\\/key.pem;/" /etc/nginx/sites-available/22222
	fi
	service nginx reload

fi
