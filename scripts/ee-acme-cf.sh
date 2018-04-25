# .bashrc functions to automate ssl certificate installation with acme.sh
# 

ee-ssl-www ()
{
clear
echo ""
echo "What is your domain ?: "
read -r domain_name
echo ""


if [ ! -f ~/.acme.sh/acme.sh ]; then
wget -O -  https://get.acme.sh | sh
source ~/.bashrc

echo "What is your Cloudflare email address ? :"
read -r cf_email
echo "What is your Cloudflare API Key ?" 
read -r cf_api_key
export CF_Email="$cf_email"
export CF_Key="$cf_api_key"
fi

~/.acme.sh/acme.sh --issue -d "$domain_name" -d www."$domain_name"  --keylength ec-384 --dns  dns_cf --dnssleep 60


if [ ! -d /etc/letsencrypt/live/$domain_name ]; then
  
# create folder to store certificate  
mkdir -p /etc/letsencrypt/live/$domain_name
fi

# install the cert and reload nginx
acme.sh --install-cert -d "$domain_name" --ecc \
--cert-file /etc/letsencrypt/live/$domain_name/cert.pem \
--key-file /etc/letsencrypt/live/$domain_name/key.pem \
--fullchain-file /etc/letsencrypt/live/$domain_name/fullchain.pem \
--reloadcmd "systemctl reload nginx.service"

# add certificate to the nginx vhost configuration

if [ ! -f /var/www/$domain_name/conf/nginx/ssl.conf ]; then

cat <<EOF >/var/www/$domain_name/conf/nginx/ssl.conf
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    ssl on;    
    ssl_certificate /etc/letsencrypt/live/$domain_name/fullchain.pem;
    ssl_certificate_key    /etc/letsencrypt/$domain_name/vtbox.cf/privkey.pem;
    ssl_trusted_certificate /etc/letsencrypt/$domain_name/cert.pem;
EOF
fi




if [ ! -f /etc/nginx/conf.d/force-ssl-"$domain_name".conf ]; then
  
# add the redirection from http to https

cat <<EOF >/etc/nginx/conf.d/force-ssl-"$domain_name".conf
server {
	listen 80;
  listen [::]:80;
	server_name "$domain_name" www.$domain_name;
	return 301 https://$domain_name$request_uri;
}
EOF

fi



}

ee-ssl-subdomain ()
{
echo "Enter your sub-domain name: "
read -r  domain_name

if [ ! -f ~/.acme.sh/acme.sh ]; then
wget -O -  https://get.acme.sh | sh
source ~/.bashrc

echo "What is your Cloudflare email address ? :"
read -r cf_email
echo "What is your Cloudflare API Key ?" 
read -r cf_api_key
export CF_Email="$cf_email"
export CF_Key="$cf_api_key"
fi

# issue cert
acme.sh --issue -d "$domain_name" --keylength ec-384 --dns  dns_cf --dnssleep 60

if [ ! -d /etc/letsencrypt/live/$domain_name ]; then
  
# create folder to store certificate  
mkdir -p /etc/letsencrypt/live/$domain_name
fi

if [ ! -f /etc/nginx/conf.d/force-ssl-"$domain_name".conf ]; then
# add certificate to the nginx vhost configuration
cat <<EOF >/var/www/$domain_name/conf/nginx/ssl.conf
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    ssl on;
    ssl_certificate /etc/letsencrypt/live/$domain_name/fullchain.pem;
    ssl_certificate_key     /etc/letsencrypt/live/$domain_name/key.pem;
    ssl_trusted_certificate /etc/letsencrypt/live/$domain_name/cert.pem;
EOF
fi

if [ ! -f /etc/nginx/conf.d/force-ssl-"$domain_name".conf ]; then
# add the redirection from http to https
cat <<EOF >/etc/nginx/conf.d/force-ssl-"$domain_name".conf
server {
	listen 80;
  listen [::]:80;
	server_name $domain_name;
	return 301 https://$domain_name$request_uri;
}
EOF
fi

# install the cert and reload nginx
.acme.sh/acme.sh --install-cert -d "$domain_name" --ecc \
--cert-file /etc/letsencrypt/live/$domain_name/cert.pem \
--key-file /etc/letsencrypt/live/$domain_name/key.pem \
--fullchain-file /etc/letsencrypt/live/$domain_name/fullchain.pem \
--reloadcmd "systemctl reload nginx.service"

}
