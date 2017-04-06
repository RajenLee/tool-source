#!/bin/bash
set -xe

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
PHP_VERSION=${2:-"5.6"}

# install LAMP
#   * Linux
#   * Apache2
#   * MySQL
#   * PHP

## assumption: Linux(ubuntu 14.04) has been pre-installed

## prepare for installation
function pre_install {
    sudo add-apt-repository -y ppa:ondrej/php
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
    sudo apt-get install -y mysql-server php${PHP_VERSION}-mysql
    sudo apt-get install -y mysql-common mysql-client
    if [[ -f /etc/mysql/my.cnf ]]; then
        sudo cp /etc/mysql/my.cnf /etc/mysql/my.cnf.bk
    else
        sudo touch /etc/mysql/my.cnf
    fi
    sudo tee -a /etc/mysql/my.cnf <<EOF
[client]
user="${DB_USER}"
password="${DB_PASSWD}"
EOF

	#sudo sed -i -r "/\[client\]/auser=$DB_USER\npassword=$DB_PASSWD" /etc/mysql/my.cnf 
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
    sudo apt-get install -y php5
    sudo apt-get install -y libapache2-mod-php5
    sudo apt-get install -y php5-mcrypt
    sudo apt-get install -y php5-gd
    sudo apt-get install -y php5-curl
    # for ubuntu 14.04
    sudo apt-get install -y libssh2-php
    # for ubuntu 16.04
    #sudo apt-get install -y php-ssh2
    sudo apt-get install -y php5-cli
    sudo apt-get install -y php5-mysqlnd-ms
}

function php5X_install {
    sudo apt-get install -y php${PHP_VERSION}
    sudo apt-get install -y libapache2-mod-php${PHP_VERSION}
    sudo apt-get install -y php${PHP_VERSION}-mcrypt
    sudo apt-get install -y php${PHP_VERSION}-gd
    sudo apt-get install -y php${PHP_VERSION}-curl
    # for ubuntu 14.04
    #sudo apt-get install -y libssh2-php
    # for ubuntu 16.04
    sudo apt-get install -y php-ssh2
    sudo apt-get install -y php${PHP_VERSION}-cli
    sudo apt-get install -y php${PHP_VERSION}-mysqlnd-ms
}


function php5_config {
	sudo cp /etc/php5/apache2/php.ini /etc/php5/apache2/php.ini.bk
    sudo sed -i -r "s/^expose_php.+/expose_php = Off/" /etc/php5/apache2/php.ini
    sudo sed -i -r "s/^allow_url_fopen.+/allow_url_fopen = Off/" /etc/php5/apache2/php.ini
    sudo service apache2 restart
    sudo a2enmod rewrite
	sudo cp /etc/apache2/mods-enabled/dir.conf /etc/apache2/mods-enabled/dir.conf.bk
    sudo sed -i -r "s/(.*)DirectoryIndex(.*)index.php(.*)/\1DirectoryIndex index.php\2\3/" /etc/apache2/mods-enabled/dir.conf
    sudo service apache2 restart
    
}

function php5X_config {
	sudo cp /etc/php/${PHP_VERSION}/apache2/php.ini /etc/php/${PHP_VERSION}/apache2/php.ini.bk
    sudo sed -i -r "s/^expose_php.+/expose_php = Off/" /etc/php/${PHP_VERSION}/apache2/php.ini
    sudo sed -i -r "s/^allow_url_fopen.+/allow_url_fopen = Off/" /etc/php/${PHP_VERSION}/apache2/php.ini
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
php5_config
wordpress_download
mysql_import
