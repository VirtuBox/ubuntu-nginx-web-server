#!/bin/bash

# automated EasyEngine server configuration script
# currently in progress, not ready to be used in production yet

CSI="\\033["
CEND="${CSI}0m"
CRED="${CSI}1;31m"
CGREEN="${CSI}1;32m"

##################################
# Variables
##################################

EXTPLORER_VER="2.1.10"
BASH_SNIPPETS_VER="1.22.0"
REPO_PATH="/tmp/ubuntu-nginx-web-server"

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
echo "Do you want to install ufw (firewall) ? (y/n)"
while [[ $ufw != "y" && $ufw != "n" ]]; do
    read -p "Select an option [y/n]: " ufw
done
echo ""
echo ""
echo "Do you want to install fail2ban ? (y/n)"
while [[ $fail2ban != "y" && $fail2ban != "n" ]]; do
    read -p "Select an option [y/n]: " fail2ban
done
echo ""
echo "Do you want to install MariaDB-server 10.3 ? (y/n)"
while [[ $mariadb_server != "y" && $mariadb_server != "n" ]]; do
    read -p "Select an option [y/n]: " mariadb_server
done
if [ "$mariadb_server" = "n" ]; then
    echo ""
    echo "Do you want to install MariaDB-client ? (y/n)"
    while [[ $mariadb_client != "y" && $mariadb_client != "n" ]]; do
        read -p "Select an option [y/n]: " mariadb_client
    done
fi
echo ""
echo "Do you want to compile the last nginx-ee ? (y/n)"
while [[ $nginxee != "y" && $nginxee != "n" ]]; do
    read -p "Select an option [y/n]: " nginxee
done
echo ""
echo "Do you want php7.1-fpm ? (y/n)"
while [[ $phpfpm71 != "y" && $phpfpm71 != "n" ]]; do
    read -p "Select an option [y/n]: " phpfpm71
done
echo ""
echo "Do you want php7.2-fpm ? (y/n)"
while [[ $phpfpm72 != "y" && $phpfpm72 != "n" ]]; do
    read -p "Select an option [y/n]: " phpfpm72
done
echo ""
echo "Do you want proftpd ? (y/n)"
while [[ $proftpd != "y" && $proftpd != "n" ]]; do
    read -p "Select an option [y/n]: " proftpd
done

echo ""



##################################
# Update packages
##################################

sudo apt-get update
sudo apt-get upgrade -y && apt-get autoremove -y && apt-get clean

##################################
# UFW
##################################

ufw() {
    
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
    
}

##################################
# Useful packages
##################################

useful() {
    
    apt-get install haveged curl git unzip zip fail2ban htop nload nmon ntp -y
    
    # ntp time
    systemctl enable ntp
    
}

##################################
# clone repository
##################################

dl_repo() {
    
    cd /tmp || exit
    git clone https://github.com/VirtuBox/ubuntu-nginx-web-server.git
    
}

##################################
# Sysctl tweaks +  open_files limits
##################################

sysctl() {
    
    sudo modprobe tcp_htcp
    cp -f $REPO_PATH/etc/sysctl.conf /etc/sysctl.conf
    sysctl -p
    cp -f  $REPO_PATH/etc/security/limits.conf /etc/security/limits.conf
    
    # Redis transparent_hugepage
    echo never > /sys/kernel/mm/transparent_hugepage/enabled
    
}

##################################
# Add MariaDB 10.3 repository
##################################

mariadb_repo() {
    
    curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup \
    | sudo bash -s -- --mariadb-server-version=10.3 --skip-maxscale -y
    sudo apt-get update
    
}

##################################
# MariaDB 10.3 install
##################################

mariadb_setup() {
    
    sudo apt-get install -y mariadb-server
    
}

mariadb_client() {
    
    sudo apt-get install -y mariadb-client
    
}

##################################
# MariaDB tweaks
##################################

mariadb_tweaks() {
    
    cp -f $REPO_PATH/etc/mysql/my.cnf /etc/mysql/my.cnf
    
    sudo service mysql stop
    
    sudo mv /var/lib/mysql/ib_logfile0 /var/lib/mysql/ib_logfile0.bak
    sudo mv /var/lib/mysql/ib_logfile1 /var/lib/mysql/ib_logfile1.bak
    
    cp -f  $REPO_PATH/etc/systemd/system/mariadb.service.d/limits.conf /etc/systemd/system/mariadb.service.d/limits.conf
    sudo systemctl daemon-reload
    
    sudo service mysql start
    
}

##################################
# EasyEngine automated install
##################################

ee_install() {
    
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

ee_fix() {
    
    cd ~/ || exit
    curl -sS https://getcomposer.org/installer | php
    mv composer.phar /usr/bin/composer
    
    chown www-data:www-data /var/www
    sudo -u www-data -H composer update -d /var/www/22222/htdocs/db/pma/
    
}

##################################
# Allow www-data shell access for SFTP + add .bashrc settings et completion
##################################

web_user() {
    
    usermod -s /bin/bash www-data
    
    wget -O /etc/bash_completion.d/wp-completion.bash https://raw.githubusercontent.com/wp-cli/wp-cli/master/utils/wp-completion.bash
    cp -f  /var/www/.profile $REPO_PATH/files/var/www/.profile
    cp -f  /var/www/.bashrc $REPO_PATH/files/var/www/.bashrc
    
    chown www-data:www-data /var/www/.profile
    chown www-data:www-data /var/www/.bashrc
    
    sudo -u www-data -H wget https://raw.githubusercontent.com/scopatz/nanorc/files/install.sh -O- | sh
    
}

##################################
# Install php7.1-fpm
##################################

php71() {
    
    sudo apt-get install php7.1-fpm php7.1-cli php7.1-zip php7.1-opcache php7.1-mysql php7.1-mcrypt php7.1-mbstring php7.1-json php7.1-intl \
    php7.1-gd php7.1-curl php7.1-bz2 php7.1-xml php7.1-tidy php7.1-soap php7.1-bcmath -y php7.1-xsl
    
    sudo cp -f $REPO_PATH/etc/php/7.1/fpm/pool.d/www.conf /etc/php/7.1/fpm/pool.d/www.conf
    
    sudo cp -f  $REPO_PATH/etc/php/7.1/fpm/php.ini /etc/php/7.1/fpm/php.ini
    cp -f  $REPO_PATH/etc/php/7.1/cli/php.ini /etc/php/7.1/cli/php.ini
    sudo service php7.1-fpm restart
    
}


##################################
# Install php7.2-fpm
##################################

php72() {
    
    sudo apt-get install php7.2-fpm php7.2-xml php7.2-bz2  php7.2-zip php7.2-mysql  php7.2-intl php7.2-gd php7.2-curl php7.2-soap php7.2-mbstring -y
    
    cp -f  $REPO_PATH/etc/php/7.2/fpm/pool.d/www.conf /etc/php/7.2/fpm/pool.d/www.conf
    cp -f  $REPO_PATH/etc/php/7.2/cli/php.ini /etc/php/7.2/cli/php.ini
    service php7.2-fpm restart
    
}

##################################
# Update php7.0-fpm config
##################################

php7_conf() {
    
    if [ ! -d /etc/php/7.0 ];
    then
        
        cp -f  $REPO_PATH/etc/php/7.0/cli/php.ini /etc/php/7.0/cli/php.ini
        cp -f  $REPO_PATH/etc/php/7.0/fpm/php.ini /etc/php/7.0/fpm/php.ini
        
    fi
    
}

##################################
# Compile latest nginx release from source
##################################

nginx_ee() {
    
    wget https://raw.githubusercontent.com/VirtuBox/nginx-ee/master/nginx-build.sh
    chmod +x nginx-build.sh
    ./nginx-build.sh
    
}

##################################
# Add nginx additional conf
##################################

nginx_conf() {

# php7.1 & 7.2 common configurations

cp -rf $REPO_PATH/etc/nginx/common/* /etc/nginx/common/

# optimized nginx.config
cp -f  $REPO_PATH/etc/nginx/nginx.conf /etc/nginx/nginx.conf


# check nginx configuration
CONF_22222=$(grep -c netdata /etc/nginx/sites-available/22222)
CONF_UPSTREAM=$(grep -c netdata /etc/nginx/conf.d/upstream.conf)
CONF_DEFAULT=$(grep -c status /etc/nginx/sites-available/default)

if [ "$CONF_22222" = 0 ]
then
    # add nginx reverse-proxy for netdata on https://yourserver.hostname:22222/netdata/
    sudo cp -f  $REPO_PATH/etc/nginx/sites-available/22222 /etc/nginx/sites-available/22222
fi

if [ "$CONF_UPSTREAM" = 0 ]
then
    # add netdata, php7.1 and php7.2 upstream
    sudo cp -f  $REPO_PATH/etc/nginx/conf.d/upstream.conf /etc/nginx/conf.d/upstream.conf
fi

if [ "$CONF_DEFAULT" = 0 ]
then
    # additional nginx locations for monitoring
    sudo cp -f  $REPO_PATH/etc/nginx/sites-available/default /etc/nginx/sites-available/default
fi

# 1) add webp mapping
cp -f $REPO_PATH/etc/nginx/conf.d/webp.conf /etc/nginx/conf.d/webp.conf

nginx -t
service nginx reload

}

##################################
# Add fail2ban configurations
##################################

f2b() {
    
    cp -f $REPO_PATH/etc/fail2ban/filter.d/ddos.conf /etc/fail2ban/filter.d/ddos.conf
    cp -f $REPO_PATH/etc/fail2ban/filter.d/ee-wordpress.conf /etc/fail2ban/filter.d/ee-wordpress.conf
    cp -f $REPO_PATH/etc/fail2ban/jail.d/custom.conf /etc/fail2ban/jail.d/custom.conf
    cp -f $REPO_PATH/etc/fail2ban/jail.d/ddos.conf  /etc/fail2ban/jail.d/ddos.conf
    
    sudo fail2ban-client reload
    
}

##################################
# Install cheat & nanorc
##################################

bashrc_extra() {
    
    git clone https://github.com/alexanderepstein/Bash-Snippets .Bash-Snippets
    cd .Bash-Snippets || exit
    git checkout v$BASH_SNIPPETS_VER
    ./install.sh cheat
    
    wget https://raw.githubusercontent.com/scopatz/nanorc/files/install.sh -O- | sh
    
}

##################################
# Install ucaresystem
##################################

ucaresystem() {
    
    sudo add-apt-repository ppa:utappia/stable -y
    sudo apt-get update
    sudo apt-get install ucaresystem-core -y
    
}

##################################
# Install ProFTPd
##################################

proftpd_setup() {
    
    sudo apt install proftpd -y
    
    # secure proftpd and enable PassivePorts
    
    sed -i 's/# DefaultRoot/DefaultRoot/' /etc/proftpd/proftpd.conf
    sed -i 's/# RequireValidShell/RequireValidShell/' /etc/proftpd/proftpd.conf
    sed -i 's/# PassivePorts                  49152 65534/PassivePorts                  49000 50000/' /etc/proftpd/proftpd.conf
    
    sudo service proftpd restart
    
    if [ "$ufw" = "y" ];
    then
        
        # ftp passive ports
        ufw allow 49000:50000/tcp
    fi
    
}

##################################
# Install Netdata
##################################

netdata() {
    
    if [ ! -d /etc/netdata ];
    then
        
        ## install dependencies
        sudo apt-get install autoconf autoconf-archive autogen automake gcc libmnl-dev lm-sensors make nodejs pkg-config python python-mysqldb python-psycopg2 python-pymongo python-yaml uuid-dev zlib1g-dev -y
        
        ## install nedata
        bash <(curl -Ss https://my-netdata.io/kickstart.sh) all --dont-wait
        
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

extplorer() {
    
    if [ ! -d /var/www/22222/htdocs/files ];
    then
        
        mkdir /var/www/22222/htdocs/files
        wget http://extplorer.net/attachments/download/74/eXtplorer_$EXTPLORER_VER.zip -O /var/www/22222/htdocs/files/ex.zip
        cd /var/www/22222/htdocs/files && unzip ex.zip && rm ex.zip
    fi
    
}

##################################
# Install EasyEngine Dashboard
##################################

ee_dashboard() {
    
    cd /var/www/22222 || exit
    
    ## download latest version of EasyEngine-dashboard
    cd /tmp || exit
    git clone https://github.com/VirtuBox/easyengine-dashboard.git
    sudo cp -rf /tmp/easyengine-dashboard/* /var/www/22222/htdocs/
    sudo chown -R www-data:www-data /var/www/22222/htdocs
    
}


##################################
# Functions 
##################################

useful
sysctl
dl_repo

if [ "$ufw" = "y" ]
then
    ufw
fi

mariadb_repo

if [ "$mariadb_server" = "y" ]
then
    mariadb_setup
    mariadb_tweaks
fi

if [ "$mariadb_client" = "y" ]
then
    mariadb_client
fi

ee_install
ee_setup
ee_fix
web_user
php7_conf

if [ "$phpfpm71" = "y" ]
then
    php71
fi

if [ "$phpfpm72" = "y" ]
then
    php72
fi

if [ "$nginxee" = "y" ]
then
    nginx_ee
    nginx_conf
fi

if [ "$fail2ban" = "y" ]
then
    f2b
fi

if [ "$proftpd" = "y" ]
then
    proftpd_setup
fi

bashrc_extra
#ucaresystem

netdata
extplorer
ee_dashboard












