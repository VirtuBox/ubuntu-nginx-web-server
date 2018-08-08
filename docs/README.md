# Bash Script to setup an EasyEngine v3 optimized

* * *

## Server Stack

- Nginx 1.15.x / 1.14.x
- PHP-FPM 7/7.1/7.2
- MariaDB 10.1/10.2/10.3
- REDIS 4.0
- Fail2ban & UFW
- Netdata
- Proftpd
- Acme.sh

* * *

**Documentation is still available here : [Ubuntu-Nginx-Web-Server](https://virtubox.github.io/ubuntu-nginx-web-server/docs/pages/documentation.md)**

### Features

- Automated MariaDB install (10.1/10.2/10.3)
- Apply Linux server tweaks
- Install EasyEngine
- Install php7.1-fpm & php7.2-fpm
- Compile the latest Nginx release
- Install and configure UFW & Fail2ban
- Install Netdata and EasyEngine-Dashboard
- Install Proftpd
-

### Compatibility

- Ubuntu 16.04 LTS
- Ubuntu 18.04 LTS

### Usage

```bash
wget https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/init.sh
chmod +x init.sh
./init.sh
```

Published & maintained by [VirtuBox](https://virtubox.net)
