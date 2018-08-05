#!/bin/bash

# automated EasyEngine server configuration script
# currently in progress, not ready to be used in production yet

#CSI="\\033["
#CEND="${CSI}0m"
#CRED="${CSI}1;31m"
#CGREEN="${CSI}1;32m"

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
	echo "Do you want to install MariaDB-client ? (y/n)"
	while [[ $mariadb_client_install != "y" && $mariadb_client_install != "n" ]]; do
		read -p "Select an option [y/n]: " mariadb_client_install
	done
fi
if [[ "$mariadb_server_install" = "y" || "$mariadb_client_install" = "y" ]]; then
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

echo "updating packages"
apt-get update >> /tmp/ubuntu-nginx-web-server.log
apt-get upgrade -y >> /tmp/ubuntu-nginx-web-server.log
apt-get autoremove -y --purge >> /tmp/ubuntu-nginx-web-server.log
apt-get autoclean -y >> /tmp/ubuntu-nginx-web-server.log

##################################
# UFW
##################################

ufw_setup() {

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

	ufw allow 161
	ufw allow 6556
	ufw allow 10050

}

##################################
# Useful packages
##################################

useful_packages_setup() {

	echo "installing useful packages"
	apt-get install haveged curl git unzip zip fail2ban htop nload nmon ntp -y >>/tmp/ubuntu-nginx-web-server.log

	# ntp time
	systemctl enable ntp

}

##################################
# clone repository
##################################

dl_git_repo_setup() {

	cd /tmp || exit
	rm -rf /tmp/ubuntu-nginx-web-server
	git clone https://github.com/VirtuBox/ubuntu-nginx-web-server.git

}

##################################
# Sysctl tweaks +  open_files limits
##################################

sysctl_tweaks_setup() {

	sudo modprobe tcp_htcp
	cp -f $REPO_PATH/etc/sysctl.conf /etc/sysctl.conf
	sysctl -p
	cp -f $REPO_PATH/etc/security/limits.conf /etc/security/limits.conf

	# Redis transparent_hugepage
	echo never >/sys/kernel/mm/transparent_hugepage/enabled

}

##################################
# Add MariaDB 10.3 repository
##################################

mariadb_repo_setup() {

	curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | \
	sudo bash -s -- --mariadb-server-version=$mariadb_version_install --skip-maxscale -y
	apt-get update >>/tmp/ubuntu-nginx-web-server.log

}

##################################
# MariaDB 10.3 install
##################################

mariadb_setup() {

	rootpass=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
	export DEBIAN_FRONTEND=noninteractive # to avoid prompt during installation
	sudo debconf-set-selections <<<"mariadb-server-$mariadb_version_install mysql-server/root_password password $rootpass"
	sudo debconf-set-selections <<<"mariadb-server-$mariadb_version_install mysql-server/root_password_again password $rootpass"
	# install mariadb server
	sudo DEBIAN_FRONTEND=noninteractive apt-get install -qq mariadb-server # -qq implies -y --force-yes

	# set password to the root user and grant privileges
	Q1="GRANT ALL PRIVILEGES on *.* to 'root'@'localhost' IDENTIFIED BY '$rootpass' WITH GRANT OPTION;"
	Q2="FLUSH PRIVILEGES;"
	SQL="${Q1}${Q2}"
	mysql -uroot -e "$SQL"

	sudo bash -c 'echo -e "[client]\n\tuser = root\n\tpassword = $rootpass" > $HOME/.my.cnf'

}

mariadb_client_setup() {

	apt-get install -y mariadb-client >>/tmp/ubuntu-nginx-web-server.log

}

##################################
# MariaDB tweaks
##################################

mariadb_tweaks_setup() {

	cp -f $REPO_PATH/etc/mysql/my.cnf /etc/mysql/my.cnf

	sudo service mysql stop

	sudo mv /var/lib/mysql/ib_logfile0 /var/lib/mysql/ib_logfile0.bak
	sudo mv /var/lib/mysql/ib_logfile1 /var/lib/mysql/ib_logfile1.bak

	cp -f $REPO_PATH/etc/systemd/system/mariadb.service.d/limits.conf /etc/systemd/system/mariadb.service.d/limits.conf
	sudo systemctl daemon-reload

	sudo service mysql start

}

##################################
# EasyEngine automated install
##################################

ee_install_setup() {

	sudo bash -c 'echo -e "[user]\n\tname = $USER\n\temail = $USER@$HOSTNAME" > $HOME/.gitconfig'
	sudo wget -qO ee rt.cx/ee && sudo bash ee

	source /etc/bash_completion.d/ee_auto.rc

}

##################################
# EasyEngine stacks install
##################################

ee_setup() {

	ee stack install
	ee stack install --php7 --redis --admin --phpredisadmin

}

##################################
# Fix phpmyadmin install
##################################

ee_fix_setup() {

	cd ~/ || exit
	curl -sS https://getcomposer.org/installer | php >>/tmp/ubuntu-nginx-web-server.log
	mv composer.phar /usr/bin/composer

	chown www-data:www-data /var/www
	sudo -u www-data -H composer update -d /var/www/22222/htdocs/db/pma/

}

##################################
# Allow www-data shell access for SFTP + add .bashrc settings et completion
##################################

web_user_setup() {

	usermod -s /bin/bash www-data

	wget -O /etc/bash_completion.d/wp-completion.bash https://raw.githubusercontent.com/wp-cli/wp-cli/master/utils/wp-completion.bash >>/tmp/ubuntu-nginx-web-server.log
	cp -f /var/www/.profile $REPO_PATH/files/var/www/.profile
	cp -f /var/www/.bashrc $REPO_PATH/files/var/www/.bashrc

	chown www-data:www-data /var/www/.profile
	chown www-data:www-data /var/www/.bashrc

	sudo -u www-data -H wget https://raw.githubusercontent.com/scopatz/nanorc/files/install.sh -O- | sh

}

##################################
# Install php7.1-fpm
##################################

php71_setup() {

	apt-get install php7.1-fpm php7.1-cli php7.1-zip php7.1-opcache php7.1-mysql php7.1-mcrypt php7.1-mbstring php7.1-json php7.1-intl \
		php7.1-gd php7.1-curl php7.1-bz2 php7.1-xml php7.1-tidy php7.1-soap php7.1-bcmath -y php7.1-xsl >>/tmp/ubuntu-nginx-web-server.log

	sudo cp -f $REPO_PATH/etc/php/7.1/fpm/pool.d/www.conf /etc/php/7.1/fpm/pool.d/www.conf

	sudo cp -f $REPO_PATH/etc/php/7.1/fpm/php.ini /etc/php/7.1/fpm/php.ini
	cp -f $REPO_PATH/etc/php/7.1/cli/php.ini /etc/php/7.1/cli/php.ini
	sudo service php7.1-fpm restart

}

##################################
# Install php7.2-fpm
##################################

php72_setup() {

	apt-get install php7.2-fpm php7.2-xml php7.2-bz2 php7.2-zip php7.2-mysql php7.2-intl php7.2-gd php7.2-curl php7.2-soap php7.2-mbstring -y >>/tmp/ubuntu-nginx-web-server.log

	cp -f $REPO_PATH/etc/php/7.2/fpm/pool.d/www.conf /etc/php/7.2/fpm/pool.d/www.conf
	cp -f $REPO_PATH/etc/php/7.2/cli/php.ini /etc/php/7.2/cli/php.ini
	service php7.2-fpm restart

}

##################################
# Update php7.0-fpm config
##################################

php7_conf_setup() {

	if [ ! -d /etc/php/7.0 ]; then

		cp -f $REPO_PATH/etc/php/7.0/cli/php.ini /etc/php/7.0/cli/php.ini
		cp -f $REPO_PATH/etc/php/7.0/fpm/php.ini /etc/php/7.0/fpm/php.ini

	fi

}

##################################
# Compile latest nginx release from source
##################################

nginx_ee_setup() {

	wget https://raw.githubusercontent.com/VirtuBox/nginx-ee/master/nginx-build.sh
	chmod +x nginx-build.sh
	./nginx-build.sh

}

##################################
# Add nginx additional conf
##################################

nginx_conf_setup() {

	# php7.1 & 7.2 common configurations

	cp -rf $REPO_PATH/etc/nginx/common/* /etc/nginx/common/

	# optimized nginx.config
	cp -f $REPO_PATH/etc/nginx/nginx.conf /etc/nginx/nginx.conf

	# check nginx configuration
	CONF_22222=$(grep -c netdata /etc/nginx/sites-available/22222)
	CONF_UPSTREAM=$(grep -c netdata /etc/nginx/conf.d/upstream.conf)
	CONF_DEFAULT=$(grep -c status /etc/nginx/sites-available/default)

	if [ "$CONF_22222" = 0 ]; then
		# add nginx reverse-proxy for netdata on https://yourserver.hostname:22222/netdata/
		sudo cp -f $REPO_PATH/etc/nginx/sites-available/22222 /etc/nginx/sites-available/22222
	fi

	if [ "$CONF_UPSTREAM" = 0 ]; then
		# add netdata, php7.1 and php7.2 upstream
		sudo cp -f $REPO_PATH/etc/nginx/conf.d/upstream.conf /etc/nginx/conf.d/upstream.conf
	fi

	if [ "$CONF_DEFAULT" = 0 ]; then
		# additional nginx locations for monitoring
		sudo cp -f $REPO_PATH/etc/nginx/sites-available/default /etc/nginx/sites-available/default
	fi

	# 1) add webp mapping
	cp -f $REPO_PATH/etc/nginx/conf.d/webp.conf /etc/nginx/conf.d/webp.conf

	nginx -t
	service nginx reload

}

##################################
# Add fail2ban configurations
##################################

f2b_setup() {

	cp -f $REPO_PATH/etc/fail2ban/filter.d/ddos.conf /etc/fail2ban/filter.d/ddos.conf
	cp -f $REPO_PATH/etc/fail2ban/filter.d/ee-wordpress.conf /etc/fail2ban/filter.d/ee-wordpress.conf
	cp -f $REPO_PATH/etc/fail2ban/jail.d/custom.conf /etc/fail2ban/jail.d/custom.conf
	cp -f $REPO_PATH/etc/fail2ban/jail.d/ddos.conf /etc/fail2ban/jail.d/ddos.conf

	fail2ban-client reload >>/tmp/ubuntu-nginx-web-server.log

}

##################################
# Install cheat & nanorc
##################################

bashrc_extra_setup() {

	curl https://cht.sh/:cht.sh >/usr/bin/cht.sh
	chmod +x /usr/bin/cht.sh
	curl https://cht.sh/:bash_completion >/etc/bash_completion.d/cht.sh
	sed -i 's/complete -F _cht_complete cht.sh/complete -F _cht_complete cheat/' /etc/bash_completion.d/cht.sh

	cd || exit
	echo "alias cheat='cht.sh'" >>.bashrc
	source .bashrc

	wget https://raw.githubusercontent.com/scopatz/nanorc/files/install.sh -O- | sh

}

##################################
# Install ucaresystem
##################################

ucaresystem_setup() {

	add-apt-repository ppa:utappia/stable -y >>/tmp/ubuntu-nginx-web-server.log
	apt-get update >>/tmp/ubuntu-nginx-web-server.log
	apt-get install ucaresystem-core -y >>/tmp/ubuntu-nginx-web-server.log

}

##################################
# Install ProFTPd
##################################

proftpd_setup() {

	echo "installing proftpd"
	apt-get install proftpd -y >>/tmp/ubuntu-nginx-web-server.log

	# secure proftpd and enable PassivePorts

	sed -i 's/# DefaultRoot/DefaultRoot/' /etc/proftpd/proftpd.conf
	sed -i 's/# RequireValidShell/RequireValidShell/' /etc/proftpd/proftpd.conf
	sed -i 's/# PassivePorts                  49152 65534/PassivePorts                  49000 50000/' /etc/proftpd/proftpd.conf

	sudo service proftpd restart

	if [ "$ufw_install" = "y" ]; then

		# ftp passive ports
		ufw allow 49000:50000/tcp
	fi

}

##################################
# Install Netdata
##################################

netdata_setup() {

	if [ ! -d /etc/netdata ]; then

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

	fi

}

##################################
# Install eXtplorer
##################################

extplorer_setup() {

	if [ ! -d /var/www/22222/htdocs/files ]; then

		mkdir /var/www/22222/htdocs/files
		wget http://extplorer.net/attachments/download/74/eXtplorer_$EXTPLORER_VER.zip -O /var/www/22222/htdocs/files/ex.zip >>/tmp/ubuntu-nginx-web-server.log
		cd /var/www/22222/htdocs/files || exit
		unzip ex.zip >>/tmp/ubuntu-nginx-web-server.log
		rm ex.zip
	fi

}

##################################
# Install EasyEngine Dashboard
##################################

ee_dashboard_setup() {

	cd /var/www/22222 || exit

	## download latest version of EasyEngine-dashboard
	cd /tmp || exit
	git clone https://github.com/VirtuBox/easyengine-dashboard.git >>/tmp/ubuntu-nginx-web-server.log
	cp -rf /tmp/easyengine-dashboard/* /var/www/22222/htdocs/ >>/tmp/ubuntu-nginx-web-server.log
	chown -R www-data:www-data /var/www/22222/htdocs >>/tmp/ubuntu-nginx-web-server.log

}

##################################
# Install Acme.sh
##################################

acme_sh_setup() {

	# install acme.sh if needed
	echo ""
	echo "checking if acme.sh is already installed"
	echo ""
	if [ ! -f $HOME/.acme.sh/acme.sh ]; then
		echo ""
		echo "installing acme.sh"
		echo ""
		wget -O - https://get.acme.sh | sh
		cd || exit
		source .bashrc
	fi

}

##################################
# Secure EasyEngine Dashboard with Acme.sh
##################################

ee-acme-22222() {

	MY_HOSTNAME=$(hostname -f)
	MY_IP=$(curl -s v4.vtbox.net)
	MY_HOSTNAME_IP=$(dig +short @8.8.8.8 "$MY_HOSTNAME")

	if [[ "$MY_IP" == "$MY_HOSTNAME_IP" ]]; then

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
}

##################################
# Functions
##################################

useful_packages_setup
dl_git_repo_setup
sysctl_tweaks_setup

ufw_setup

mariadb_repo_setup

if [ "$mariadb_server_install" = "y" ]; then
	mariadb_setup
	mariadb_tweaks_setup
elif [ "$mariadb_client_install" = "y" ]; then
	mariadb_client_setup
fi

ee_install_setup
ee_setup
ee_fix_setup
web_user_setup
php7_conf_setup

if [ "$phpfpm71_install" = "y" ]; then
	php71_setup
fi

if [ "$phpfpm72_install" = "y" ]; then
	php72_setup
fi

nginx_ee_setup
nginx_conf_setup

f2b_setup

if [ "$proftpd_install" = "y" ]; then
	proftpd_setup
fi

bashrc_extra_setup
#ucaresystem

netdata_setup
extplorer_setup
ee_dashboard_setup

acme_sh_setup
ee-acme-22222
