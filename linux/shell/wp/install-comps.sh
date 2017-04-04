#!/bin/bash

# author rajen
# date 1/19/2017
# version 0

if [ $EUID != 0 ]; then
    echo "Must run with root rule..."
    exit 1
fi

if [[ -z $1 ]]; then
	echo "pls input a paramter"
	exit 1
fi

IP_ADDR=$(ifconfig|grep inet|awk '{print $2}'|head -1)
DB_USER='root'
DB_PASSWD=$1
DB_WORDPRESS_NAME='wordpress'
DB_WORDPRESS_USER=$1
DB_WORDPRESS_PASSWD=$1

# install LAMP
#   * Linux
#   * Apache2
#   * MySQL
#   * PHP

## assumption: Linux(ubuntu 14.04) has been pre-installed

## prepare for installation
function pre_install {
    sudo apt-get update
}

## install Apache2
function apache_install {
    sudo apt-get install -y apache2
	sudo cp /etc/apache2/apache2.conf /etc/apache2/apache2.conf.bk
    echo "ServerName $(hostname)" | sudo tee -a /etc/apache2/apache2.conf
	sudo cp /etc/hosts /etc/hosts.bk
    sudo sed -i "2i127.0.0.1 $(hostname)" /etc/hosts
    sudo sed -i "3i127.0.1.1 $(hostname)" /etc/hosts
	sudo service apache2 restart
}

## install MySQL and create database:wordpress 
function mysql_install {
    sudo apt-get install -y mysql-server php5-mysql
	sudo cp /etc/mysql/my.cnf /etc/mysql/my.cnf.bk
	sudo sed -i -r "/\[client\]/auser=$DB_USER\npassword=$DB_PASSWD" /etc/mysql/my.cnf 
	sudo service mysql restart

}

function mysql_create_db {
    mysql -u $DB_USER -e "DROP DATABASE IF EXISTS $DB_WORDPRESS_NAME;"
    mysql -u $DB_USER -e "CREATE DATABASE IF NOT EXISTS $DB_WORDPRESS_NAME;"
	## IMPORTANT: pls make sure $DB_WORDPRESS_USER not exist in db
    mysql -u $DB_USER -e "CREATE USER $DB_WORDPRESS_USER@localhost IDENTIFIED BY '$DB_WORDPRESS_PASSWD';"
    mysql -u $DB_USER -e "GRANT ALL PRIVILEGES ON ${DB_WORDPRESS_NAME}.* TO $DB_WORDPRESS_USER@localhost;"
    mysql -u $DB_USER -e "FLUSH PRIVILEGES;"
}

function mysql_import {
    if [[ -e ~/.wordpress/wordpress.sql ]]; then
        mysql -u root -e "use wordpress; source ~/.wordpress/wordpress.sql;"
    else
        echo "prepare for sql dump file"; exit 1 
    fi
}

function mysql_export {
    [[ -d ~/.wordpress ]] || mkdir ~/.wordpress
    mysqldump -u root wordpress > ~/.wordpress/wordpress.sql
}
## install php
function php_install {
    sudo apt-get install -y php5 libapache2-mod-php5 php5-mcrypt
    sudo apt-get install -y php5-gd php5-curl libssh2-php
    sudo apt-get install -y php5-cli
    sudo apt-get install -y php5-mysqlnd-ms
}

function php_config {
	sudo cp /etc/php5/apache2/php.ini /etc/php5/apache2/php.ini.bk
    sudo sed -i -r "s/^expose_php.+/expose_php = Off/" /etc/php5/apache2/php.ini
    sudo sed -i -r "s/^allow_url_fopen.+/allow_url_fopen = Off/" /etc/php5/apache2/php.ini
    sudo service apache2 restart
    sudo a2enmod rewrite
	sudo cp /etc/apache2/mods-enabled/dir.conf /etc/apache2/mods-enabled/dir.conf.bk
    sudo sed -i -r "s/(.*)DirectoryIndex(.*)index.php(.*)/\1DirectoryIndex index.php\2\3/" /etc/apache2/mods-enabled/dir.conf
    sudo service apache2 restart
    
}


# download wordpress
function wordpress_download {
    cd /tmp/
    wget http://wordpress.org/latest.tar.gz
    tar -xvf latest.tar.gz

    if [[ ! -d wordpress ]]; then
        echo "wordpress dir is no exist..."
        exit 1
    fi
    sudo rsync -avz wordpress/* /var/www/html
    cd /var/www/html
    sudo chown www-data:www-data -R /var/www/html
    cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
    sed -i "s/database_name_here/$DB_WORDPRESS_NAME/" /var/www/html/wp-config.php
    sed -i "s/username_here/$DB_WORDPRESS_USER/" /var/www/html/wp-config.php
    sed -i "s/password_here/$DB_WORDPRESS_PASSWD/" /var/www/html/wp-config.php
    sudo service apache2 restart
}

pre_install
apache_install
mysql_install
mysql_create_db
php_install
php_config
wordpress_download

