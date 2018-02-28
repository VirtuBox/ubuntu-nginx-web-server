# .bashrc functions to automate ssl certificate installation with acme.sh
# 

ssl-ee-domain ()
{
read -p "Enter your domain name: " domain_name

~/.acme.sh/acme.sh --issue -d $domain_name -d www.$domain_name  --keylength ec-384 --dns  dns_cf --dnssleep 60


# create folder to store certificate
mkdir -p /etc/nginx/acme.sh/$domain_name

# add certificate to the nginx vhost configuration
cat <<EOF >/var/www/$domain_name/conf/nginx/ssl.conf
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    ssl on;
    ssl_certificate /etc/nginx/acme.sh/$domain_name/fullchain.pem;
    ssl_certificate_key     /etc/nginx/acme.sh/$domain_name/key.pem;
    ssl_trusted_certificate /etc/nginx/acme.sh/$domain_name/cert.pem;
EOF

# add the redirection from http to https
cat <<EOF >/etc/nginx/conf.d/$domain_name-forcessl.conf
server {
	listen 80;
    listen [::]:80;
	server_name $domain_name www.$domain_name;
	return 301 https://$domain_name$request_uri;
}
EOF

# install the cert and reload nginx
acme.sh --install-cert -d $domain_name --ecc \
--cert-file /etc/nginx/acme.sh/$domain_name/cert.pem \
--key-file /etc/nginx/acme.sh/$domain_name/key.pem \
--fullchain-file /etc/nginx/acme.sh/$domain_name/fullchain.pem \
--reloadcmd "systemctl reload nginx.service"

}

ssl-ee-subdomain ()
{
read -p "Enter your sub-domain name: " domain_name

# issue cert
~/.acme.sh/acme.sh --issue -d $domain_name --keylength ec-384 --dns  dns_cf --dnssleep 60

# create folder to store certificate
mkdir -p /etc/nginx/acme.sh/$domain_name

# add certificate to the nginx vhost configuration
cat <<EOF >/var/www/$domain_name/conf/nginx/ssl.conf
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    ssl on;
    ssl_certificate /etc/nginx/acme.sh/$domain_name/fullchain.pem;
    ssl_certificate_key     /etc/nginx/acme.sh/$domain_name/key.pem;
    ssl_trusted_certificate /etc/nginx/acme.sh/$domain_name/cert.pem;
EOF

# add the redirection from http to https
cat <<EOF >/etc/nginx/conf.d/$domain_name-forcessl.conf
server {
	listen 80;
    listen [::]:80;
	server_name $domain_name;
	return 301 https://$domain_name$request_uri;
}
EOF

# install the cert and reload nginx
/root/.acme.sh/acme.sh --install-cert -d $domain_name --ecc \
--cert-file /etc/nginx/acme.sh/$domain_name/cert.pem \
--key-file /etc/nginx/acme.sh/$domain_name/key.pem \
--fullchain-file /etc/nginx/acme.sh/$domain_name/fullchain.pem \
--reloadcmd "systemctl reload nginx.service"

}
