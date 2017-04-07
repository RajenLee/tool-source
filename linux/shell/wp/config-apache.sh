#!/bin/bash


if [[ $EUID != 0 ]]; then
	echo "pls use root role"
	exit 1
fi

if [[ ! $1 || ! $2 || ! $3 ]]; then
	echo "pls input 3 params"
	exit 1
fi

DNS_SERVER=$1
USER_EMAIL=$2
IP_SERVER=$3

sudo rm -rf /etc/apache2/sites-enabled/*
sudo mkdir /var/www/ip
sudo tee /etc/apache2/sites-enabled/dns.conf <<EOF
<VirtualHost *:80>
	ServerName $DNS_SERVER
	ServerAdmin $USER_EMAIL
	DocumentRoot /var/www/html
        <Directory /var/www/html>
            Options Indexes FollowSymLinks
            AllowOverride All
            Order allow,deny
            Allow from all
        </Directory>
</VirtualHost>
<VirtualHost *:80>
	ServerName $IP_SERVER
	DocumentRoot /var/www/ip
</VirtualHost>
EOF

sudo service apache2 restart
