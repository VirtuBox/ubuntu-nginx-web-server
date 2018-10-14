#!/bin/bash

# automated EasyEngine server configuration script
# currently in progress, not ready to be used in production yet

CSI='\033['
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

echo "#####################################"
echo "Security"
echo "#####################################"
echo ""
echo "Do you currently use default SSH port 22 ? (y/n)"
while [[ $ssh_port_default != "y" && $ssh_port_default != "n" ]]; do
    read -p "Select an option [y/n]: " ssh_port_default
done
echo ""
if [ $ssh_port_default = "y" ]; then
    echo "What custom SSH port do you want to use instead of 22 ?"
    read -p "Select a port between 1024 & 65536 : " ssh_port_select
    echo ""
else
    echo "What custom SSH port are you using ?"
    read -p "Select your custom SSH port : " ssh_port_select
    echo ""
fi
sleep 1
if [ ! -d /etc/mysql ]; then
    echo "#####################################"
    echo "MariaDB server"
    echo "#####################################"
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
    fi
    if [ "$mariadb_client_install" = "y" ]; then
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
    sleep 1
fi
echo ""
echo "#####################################"
echo "Nginx"
echo "#####################################"
echo ""
echo "Do you want to compile the latest Nginx Mainline [1] or Stable [2] Release ?"
while [[ $NGINX_RELEASE != "1" && $NGINX_RELEASE != "2" ]]; do
    read -p "Select an option [1-2]: " NGINX_RELEASE
done
echo ""
echo "Do you want Ngx_Pagespeed ? (y/n)"
while [[ $PAGESPEED != "y" && $PAGESPEED != "n" ]]; do
    read -p "Select an option [y/n]: " PAGESPEED
done
echo ""
echo "Do you want NAXSI WAF (still experimental)? (y/n)"
while [[ $NAXSI != "y" && $NAXSI != "n" ]]; do
    read -p "Select an option [y/n]: " NAXSI
    export $NAXSI
done
echo ""
echo "Do you want RTMP streaming module ?"
while [[ $RTMP != "y" && $RTMP != "n" ]]; do
    read -p "Select an option [y/n]: " RTMP
    export $RTMP
done
sleep 1
echo ""
echo "#####################################"
echo "PHP"
echo "#####################################"
echo "Do you want php7.1-fpm ? (y/n)"
while [[ $phpfpm71_install != "y" && $phpfpm71_install != "n" ]]; do
    read -p "Select an option [y/n]: " phpfpm71_install
done
echo ""
echo "Do you want php7.2-fpm ? (y/n)"
while [[ $phpfpm72_install != "y" && $phpfpm72_install != "n" ]]; do
    read -p "Select an option [y/n]: " phpfpm72_install
done
if [ ! -d /etc/proftpd ]; then
    echo ""
    echo "#####################################"
    echo "FTP"
    echo "#####################################"
    echo "Do you want proftpd ? (y/n)"
    while [[ $proftpd_install != "y" && $proftpd_install != "n" ]]; do
        read -p "Select an option [y/n]: " proftpd_install
    done
fi
echo ""
echo "#####################################"
echo "Starting server setup in 5 seconds"
echo "use CTRL + C if you want to cancel installation"
echo "#####################################"
sleep 5

##################################
# Update packages
##################################

echo "##########################################"
echo " Updating Packages"
echo "##########################################"

apt-get update
apt-get upgrade -y
apt-get autoremove -y --purge
apt-get autoclean -y

##################################
# Secure SSH server
##################################

# download secure sshd_config
wget -O /etc/ssh/sshd_config https://virtubox.github.io/ubuntu-nginx-web-server/files/etc/ssh/sshd_config

# change ssh default port
sudo sed -i "s/Port 22/Port $ssh_port_select/" /etc/ssh/sshd_config

# restart ssh service
service ssh restart

##################################
# UFW
##################################
echo "##########################################"
echo " Configuring UFW"
echo "##########################################"

if [ ! -d /etc/ufw ]; then
    apt-get install ufw -y
fi

# define firewall rules

ufw logging low
ufw default allow outgoing
ufw default deny incoming

# allow required ports
ufw allow 22
ufw allow $ssh_port_select
ufw allow 53
ufw allow http
ufw allow https
ufw allow 123

# dhcp client
ufw allow 68

# dhcp ipv6 client
ufw allow 546

# rsync
ufw allow 873

# easyengine backend
ufw allow 22222

# optional for monitoring

# SNMP UDP port
#ufw allow 161

# Netdata web interface
#ufw allow 1999

# Librenms linux agent
#ufw allow 6556

# Zabbix-agent
#ufw allow 10050


##################################
# Useful packages
##################################

echo "##########################################"
echo " Installing useful packages"
echo "##########################################"


apt-get install haveged curl git unzip zip fail2ban htop nload nmon ntp gnupg gnupg2 wget pigz tree ccze  -y

# ntp time
systemctl enable ntp

# increase history size
export HISTSIZE=10000


##################################
# clone repository
##################################
echo "##########################################"
echo " Cloning Ubuntu-nginx-web-server repository"
echo "##########################################"

cd /tmp || exit
rm -rf /tmp/ubuntu-nginx-web-server
git clone https://github.com/VirtuBox/ubuntu-nginx-web-server.git


##################################
# Sysctl tweaks +  open_files limits
##################################
echo "##########################################"
echo " Applying Linux Kernel tweaks"
echo "##########################################"

sudo modprobe tcp_htcp
cp -f $REPO_PATH/etc/sysctl.d/60-ubuntu-nginx-web-server.conf /etc/sysctl.d/60-ubuntu-nginx-web-server.conf
sysctl -e -p /etc/sysctl.d/60-ubuntu-nginx-web-server.conf
cp -f $REPO_PATH/etc/security/limits.conf /etc/security/limits.conf

# Redis transparent_hugepage
echo never >/sys/kernel/mm/transparent_hugepage/enabled

# disable ip forwarding if docker is not installed
if [ ! -x /usr/bin/docker ]; then

    echo "" >> /etc/sysctl.d/60-ubuntu-nginx-web-server.conf
    echo "# Disables packet forwarding" >> /etc/sysctl.d/60-ubuntu-nginx-web-server.conf
    echo "net.ipv4.ip_forward = 0" >> /etc/sysctl.d/60-ubuntu-nginx-web-server.conf
    echo "net.ipv4.conf.all.forwarding = 0" >> /etc/sysctl.d/60-ubuntu-nginx-web-server.conf
    echo "net.ipv4.conf.default.forwarding = 0" >> /etc/sysctl.d/60-ubuntu-nginx-web-server.conf
    echo "net.ipv6.conf.all.forwarding = 0" >> /etc/sysctl.d/60-ubuntu-nginx-web-server.conf
    echo "net.ipv6.conf.default.forwarding = 0" >> /etc/sysctl.d/60-ubuntu-nginx-web-server.conf

fi

# additional systcl configuration with network interface name
# get network interface names like eth0, ens18 or eno1
# for each interface found, add the following configuration to sysctl
NET_INTERFACES_LIST=$( ls /sys/class/net | grep -E "/(?:veth(.*))|eth(.*)|ens(.*)|eno(.*)/")
for NET_INTERFACE in $NET_INTERFACES_LIST; do
    echo "" >> /etc/sysctl.d/60-ubuntu-nginx-web-server.conf
    echo "# do not autoconfigure IPv6 on $NET_INTERFACE" >> /etc/sysctl.d/60-ubuntu-nginx-web-server.conf
    echo "net.ipv6.conf.$NET_INTERFACE.autoconf = 0" >> /etc/sysctl.d/60-ubuntu-nginx-web-server.conf
    echo "net.ipv6.conf.$NET_INTERFACE.accept_ra = 0" >> /etc/sysctl.d/60-ubuntu-nginx-web-server.conf
    echo "net.ipv6.conf.$NET_INTERFACE.accept_ra = 0" >> /etc/sysctl.d/60-ubuntu-nginx-web-server.conf
    echo "net.ipv6.conf.$NET_INTERFACE.autoconf = 0" >> /etc/sysctl.d/60-ubuntu-nginx-web-server.conf
    echo "net.ipv6.conf.$NET_INTERFACE.accept_ra_defrtr = 0" >> /etc/sysctl.d/60-ubuntu-nginx-web-server.conf
done



##################################
# Add MariaDB 10.3 repository
##################################

if [[ "$mariadb_server_install" == "y" || "$mariadb_client_install" == "y" ]]; then
    if [ ! -f /etc/apt/sources.list.d/mariadb.list ]; then
        echo ""
        echo "##########################################"
        echo " Adding MariaDB $mariadb_version_install repository"
        echo "##########################################"

        bash <(wget -qO - https://downloads.mariadb.com/MariaDB/mariadb_repo_setup) --mariadb-server-version=$mariadb_version_install --skip-maxscale -y
        apt-get update


    fi
fi

##################################
# MariaDB 10.3 install
##################################

# install mariadb server non-interactive way
if [ "$mariadb_server_install" = "y" ]; then
    if [ ! -d /etc/mysql ]; then
        echo ""
        echo "##########################################"
        echo " Installing MariaDB server $mariadb_version_install"
        echo "##########################################"

        # generate random password
        MYSQL_ROOT_PASS=$(date +%s | sha256sum | base64 | head -c 32)
        export DEBIAN_FRONTEND=noninteractive # to avoid prompt during installation
	sudo debconf-set-selections <<<"mariadb-server-$mariadb_version_install mysql-server/root_password password $MYSQL_ROOT_PASS"
	sudo debconf-set-selections <<<"mariadb-server-$mariadb_version_install mysql-server/root_password_again password $MYSQL_ROOT_PASS"
	# install mariadb server
	DEBIAN_FRONTEND=noninteractive apt-get install -qq mariadb-server  # -qq implies -y --force-yes
        # save credentials in .my.cnf and copy it in /etc/mysql/conf.d for easyengine
        sudo bash -c 'echo -e "[client]\nuser = root" > $HOME/.my.cnf'
        echo "password = $MYSQL_ROOT_PASS" >>$HOME/.my.cnf
        cp $HOME/.my.cnf /etc/mysql/conf.d/my.cnf

        ## mysql_secure_installation non-interactive way
        mysql -e "GRANT ALL PRIVILEGES on *.* to 'root'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PASS' WITH GRANT OPTION;"
        # remove anonymous users
        mysql -e "DROP USER ''@'localhost'"
        mysql -e "DROP USER ''@'$(hostname)'"
        # remove test database
        mysql -e "DROP DATABASE test"
        # flush privileges
        mysql -e "FLUSH PRIVILEGES"
    fi
fi
##################################
# MariaDB tweaks
##################################

if [ "$mariadb_server_install" = "y" ]; then
    echo "##########################################"
    echo " Optimizing MariaDB configuration"
    echo "##########################################"

    cp -f $REPO_PATH/etc/mysql/my.cnf /etc/mysql/my.cnf

    # AVAILABLE_MEMORY=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    # BUFFER_POOL_SIZE=$(( $AVAILABLE_MEMORY / 2000 ))
    # LOG_FILE_SIZE=$(( $AVAILABLE_MEMORY / 16000 ))
    # LOG_BUFFER_SIZE=$(( $AVAILABLE_MEMORY / 8000 ))


    # sudo sed -i "s/innodb_buffer_pool_size = 2G/innodb_buffer_pool_size = $BUFFER_POOL_SIZE\\M/" /etc/mysql/my.cnf
    # sudo sed -i "s/innodb_log_file_size    = 256M/innodb_log_file_size    = $LOG_FILE_SIZE\\M/" /etc/mysql/my.cnf
    # sudo sed -i "s/innodb_log_buffer_size  = 512M/innodb_log_buffer_size  = $LOG_BUFFER_SIZE\\M/" /etc/mysql/my.cnf

    # stop mysql service to apply new InnoDB log file size
    sudo service mysql stop

    # mv previous log file
    sudo mv /var/lib/mysql/ib_logfile0 /var/lib/mysql/ib_logfile0.bak
    sudo mv /var/lib/mysql/ib_logfile1 /var/lib/mysql/ib_logfile1.bak

    # increase mariadb open_files_limit
    cp -f $REPO_PATH/etc/systemd/system/mariadb.service.d/limits.conf /etc/systemd/system/mariadb.service.d/limits.conf

    # reload daemon
    systemctl daemon-reload

    # restart mysql
    service mysql start

fi
if [ "$mariadb_client_install" = "y" ]; then

    echo "installing mariadb-client"
    # install mariadb-client
    apt-get install -y mariadb-client

    # set mysql credentials in .my.cnf
    echo "[client]" >>$HOME/.my.cnf
    echo "host = $mariadb_remote_ip" >>$HOME/.my.cnf
    echo "port = 3306" >>$HOME/.my.cnf
    echo "user = $mariadb_remote_user" >>$HOME/.my.cnf
    echo "password = $mariadb_remote_password" >>$HOME/.my.cnf

    # copy .my.cnf in /etc/mysql/conf.d/ for easyengine
    cp $HOME/.my.cnf /etc/mysql/conf.d/my.cnf
fi

##################################
# EasyEngine automated install
##################################

if [ ! -f $HOME/.gitconfig ]; then
    # define git username and email for non-interactive install
    sudo bash -c 'echo -e "[user]\n\tname = $USER\n\temail = $USER@$HOSTNAME" > $HOME/.gitconfig'
fi
if [ ! -x /usr/local/bin/ee ]; then
    echo "##########################################"
    echo " Installing EasyEngine"
    echo "##########################################"

    wget -qO ee https://raw.githubusercontent.com/EasyEngine/easyengine/master/install
    bash ee
    source /etc/bash_completion.d/ee_auto.rc

fi


##################################
# EasyEngine stacks install
##################################

if [ "$mariadb_client_install" = "y" ]; then
    # change MySQL host to % in case of remote MySQL server
    sudo sed -i 's/grant-host = localhost/grant-host = \%/' /etc/ee/ee.conf
fi

echo "##########################################"
echo " Installing EasyEngine Stack"
echo "##########################################"

# install nginx, php, postfix, memcached
ee stack install
# install php7, redis, easyengine backend & phpredisadmin
ee stack install --php7 --redis --admin --phpredisadmin


##################################
# Fix phpmyadmin install
##################################
echo "##########################################"
echo " Updating phpmyadmin"
echo "##########################################"

# install composer
cd ~/ || exit
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/bin/composer

# change owner of /var/www to allow composer cache
chown www-data:www-data /var/www
# update phpmyadmin with composer
sudo -u www-data -H composer update -d /var/www/22222/htdocs/db/pma/

##################################
# Allow www-data shell access for SFTP + add .bashrc settings et completion
##################################
echo "##########################################"
echo " Configuring www-data shell access"
echo "##########################################"

# change www-data shell
usermod -s /bin/bash www-data

if [ ! -f /etc/bash_completion.d/wp-completion.bash ]; then
    # download wp-cli bash-completion
    wget -qO /etc/bash_completion.d/wp-completion.bash https://raw.githubusercontent.com/wp-cli/wp-cli/master/utils/wp-completion.bash
fi
if [ ! -f /var/www/.profile ] && [ ! -f /var/www/.bashrc ]; then
    # create .profile & .bashrc for www-data user
    cp -f $REPO_PATH/var/www/.profile /var/www/.profile
    cp -f $REPO_PATH/var/www/.bashrc /var/www/.bashrc


    # set www-data as owner
    chown www-data:www-data /var/www/.profile
    chown www-data:www-data /var/www/.bashrc
fi

# install nanorc for www-data
sudo -u www-data -H curl https://raw.githubusercontent.com/scopatz/nanorc/master/install.sh | sh

##################################
# Install php7.1-fpm
##################################

if [ "$phpfpm71_install" = "y" ]; then

    echo "##########################################"
    echo " Installing php7.1-fpm"
    echo "##########################################"

    apt-get install php7.1-fpm php7.1-cli php7.1-zip php7.1-opcache php7.1-mysql php7.1-mcrypt php7.1-mbstring php7.1-json php7.1-intl \
    php7.1-gd php7.1-curl php7.1-bz2 php7.1-xml php7.1-tidy php7.1-soap php7.1-bcmath -y php7.1-xsl -y

    # copy php7.1 config files
    sudo cp -rf $REPO_PATH/etc/php/7.1/* /etc/php/7.1/
    sudo service php7.1-fpm restart


fi

##################################
# Install php7.2-fpm
##################################

if [ "$phpfpm72_install" = "y" ]; then
    echo "##########################################"
    echo " Installing php7.2-fpm"
    echo "##########################################"

    apt-get install php7.2-fpm php7.2-xml php7.2-bz2 php7.2-zip php7.2-mysql php7.2-intl php7.2-gd \
    php7.2-curl php7.2-soap php7.2-mbstring php7.2-xsl php7.2-bcmath -y

    # copy php7.2 config files
    cp -rf $REPO_PATH/etc/php/7.2/* /etc/php/7.2/
    service php7.2-fpm restart

fi

##################################
# Update php7.0-fpm config
##################################
echo "##########################################"
echo " Configuring php7.0-fpm"
echo "##########################################"


if [ -d /etc/php/7.0 ]; then

    cp -rf $REPO_PATH/etc/php/7.0/* /etc/php/7.0/

fi



##################################
# Compile latest nginx release from source
##################################

# set nginx-ee arguments

if [ $NGINX_RELEASE = "1" ]; then
    NGINX_BUILD_VER='--mainline'
else
    NGINX_BUILD_VER='--stable'
fi

if [ $PAGESPEED = "y" ]; then
    BUILD_PAGESPEED='--pagespeed'
else
    BUILD_PAGESPEED=''
fi

if [ $NAXSI = "y" ]; then
    BUILD_NAXSI='--naxsi'
else
    BUILD_NAXSI=''
fi

if [ $RTMP = "y" ]; then
    BUILD_RTMP='--rtmp'
else
    BUILD_RTMP=''
fi

echo "##########################################"
echo " Compiling Nginx with nginx-ee"
echo "##########################################"

wget -q https://raw.githubusercontent.com/VirtuBox/nginx-ee/master/nginx-build.sh
chmod +x nginx-build.sh

./nginx-build.sh $NGINX_BUILD_VER $BUILD_PAGESPEED $BUILD_NAXSI $BUILD_RTMP


##################################
# Add nginx additional conf
##################################
echo "##########################################"
echo " Configuring Nginx"
echo "##########################################"


# php7.1 & 7.2 common configurations

cp -rf $REPO_PATH/etc/nginx/common/* /etc/nginx/common/

# common nginx configurations

cp -rf $REPO_PATH/etc/nginx/conf.d/* /etc/nginx/conf.d/
cp -f $REPO_PATH/etc/nginx/proxy_params /etc/nginx/proxy_params
cp -f $REPO_PATH/etc/nginx/mime.types /etc/nginx/mime.types



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

VERIFY_NGINX_CONFIG=$(nginx -t 2>&1 | grep failed)
echo "##########################################"
echo "Checking Nginx configuration"
echo "##########################################"
if [ -z "$VERIFY_NGINX_CONFIG" ]; then
    echo "##########################################"
    echo "Reloading Nginx"
    echo "##########################################"
    sudo service nginx reload
else
    echo "##########################################"
    echo "Nginx configuration is not correct"
    echo "##########################################"
fi


##################################
# Add fail2ban configurations
##################################
echo "##########################################"
echo " Configuring Fail2Ban"
echo "##########################################"


cp -rf $REPO_PATH/etc/fail2ban/filter.d/* /etc/fail2ban/filter.d/
cp -rf $REPO_PATH/etc/fail2ban/jail.d/* /etc/fail2ban/jail.d/

fail2ban-client reload

##################################
# Add fail2ban configurations
##################################
echo "##########################################"
echo " Installing ClamAV"
echo "##########################################"

if [ ! -x /usr/bin/clamscan ]; then
    apt-get install clamav -y
fi

##################################
# Add fail2ban configurations
##################################
echo "##########################################"
echo " Updating ClamAV signature database"
echo "##########################################"

/etc/init.d/clamav-freshclam stop
freshclam
/etc/init.d/clamav-freshclam start

##################################
# Install cheat & nanorc
##################################
echo "##########################################"
echo " Installing cheat.sh & nanorc & mysqldump script"
echo "##########################################"

if [ ! -x /usr/bin/cht.sh ]; then
    curl https://cht.sh/:cht.sh >/usr/bin/cht.sh
    chmod +x /usr/bin/cht.sh

    cd || exit
    echo "alias cheat='cht.sh'" >>.bashrc
    source $HOME/.bashrc
fi

wget https://raw.githubusercontent.com/scopatz/nanorc/master/install.sh -qO- | sh

wget -qO mysqldump.sh https://github.com/VirtuBox/bash-scripts/blob/master/backup/mysqldump/mysqldump.sh
chmod +x mysqldump.sh

##################################
# Install ProFTPd
##################################

if [ "$proftpd_install" = "y" ]; then

    echo "##########################################"
    echo " Installing Proftpd"
    echo "##########################################"

    apt-get install proftpd -y

    # secure proftpd and enable PassivePorts

    sed -i 's/# DefaultRoot/DefaultRoot/' /etc/proftpd/proftpd.conf
    sed -i 's/# RequireValidShell/RequireValidShell/' /etc/proftpd/proftpd.conf
    sed -i 's/# PassivePorts                  49152 65534/PassivePorts                  49000 50000/' /etc/proftpd/proftpd.conf

    sudo service proftpd restart

    if [ -d /etc/ufw ]; then
        # ftp active port
        ufw allow 21
        # ftp passive ports
        ufw allow 49000:50000/tcp
    fi

fi

##################################
# Install Netdata
##################################

if [ ! -d /etc/netdata ]; then
    echo "##########################################"
    echo " Installing Netdata"
    echo "##########################################"

    ## install nedata
    wget -qO kickstart.sh https://my-netdata.io/kickstart.sh
    chmod +x kickstart.sh
    ./kickstart.sh all --dont-wait >> /tmp/ubuntu-nginx-web-server.log 2>&1

    ## optimize netdata resources usage
    echo 1 >/sys/kernel/mm/ksm/run
    echo 1000 >/sys/kernel/mm/ksm/sleep_millisecs

    ## disable email notifigrep -cions
    sudo sed -i 's/SEND_EMAIL="YES"/SEND_EMAIL="NO"/' /usr/lib/netdata/conf.d/health_alarm_notify.conf
    sudo service netdata restart

fi

##################################
# Install EasyEngine Dashboard
##################################

echo "##########################################"
echo " Installing EasyEngine Dashboard"
echo "##########################################"

if [ ! -d /var/www/22222/htdocs/files ]; then

    mkdir -p /var/www/22222/htdocs/files
    wget -qO /var/www/22222/htdocs/files/ex.zip http://extplorer.net/attachments/download/74/eXtplorer_$EXTPLORER_VER.zip
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


##################################
# Install Acme.sh
##################################
echo "##########################################"
echo " Installing Acme.sh"
echo "##########################################"


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

##################################
# Secure EasyEngine Dashboard with Acme.sh
##################################

MY_HOSTNAME=$(hostname -f)
MY_IP=$(curl -s v4.vtbox.net)
MY_HOSTNAME_IP=$(dig +short @8.8.8.8 "$MY_HOSTNAME")

if [[ "$MY_IP" == "$MY_HOSTNAME_IP" ]]; then
    echo "##########################################"
    echo " Securing EasyEngine Backend"
    echo "##########################################"
    if [ ! -f /etc/systemd/system/multi-user.target.wants/nginx.service ]; then
        systemctl enable nginx.service
        service nginx start
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
    if [ -f $HOME/.acme.sh/${MY_HOSTNAME}_ecc/fullchain.cer ]; then
        $HOME/.acme.sh/acme.sh --install-cert -d ${MY_HOSTNAME} --ecc \
        --cert-file /etc/letsencrypt/live/${MY_HOSTNAME}/cert.pem \
        --key-file /etc/letsencrypt/live/${MY_HOSTNAME}/key.pem \
        --fullchain-file /etc/letsencrypt/live/${MY_HOSTNAME}/fullchain.pem \
        --reloadcmd "systemctl reload nginx.service"
    fi

    if [ -f /etc/letsencrypt/live/${MY_HOSTNAME}/fullchain.pem ] && [ -f /etc/letsencrypt/live/${MY_HOSTNAME}/key.pem ]; then
        sed -i "s/ssl_certificate \\/var\\/www\\/22222\\/cert\\/22222.crt;/ssl_certificate \\/etc\\/letsencrypt\\/live\\/${MY_HOSTNAME}\\/fullchain.pem;/" /etc/nginx/sites-available/22222
        sed -i "s/ssl_certificate_key \\/var\\/www\\/22222\\/cert\\/22222.key;/ssl_certificate_key    \\/etc\\/letsencrypt\\/live\\/${MY_HOSTNAME}\\/key.pem;/" /etc/nginx/sites-available/22222
    fi
    service nginx reload

fi
