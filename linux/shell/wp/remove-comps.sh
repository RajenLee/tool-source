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
PHP_VERSION=$2

# remove LAMP
#   * Linux
#   * Apache2
#   * MySQL
#   * PHP


## prepare for remove
function end_remove {
    sudo apt-get -y autoremove
}

## remove Apache2
function apache_remove {
    sudo apt-get remove -y apache2
	sudo mv /etc/apache2/apache2.conf.bk /etc/apache2/apache2.conf
	sudo mv /etc/hosts.bk /etc/hosts
}

## remove MySQL and create database:wordpress 
function mysql_remove {
    sudo apt-get remove -y mysql-server php${PHP_VERSION}-mysql
    sudo apt-get remove -y mysql-common mysql-client
    if [[ -f /etc/mysql/my.cnf.bk ]]; then
        sudo mv /etc/mysql/my.cnf.bk /etc/mysql/my.cnf
    else
        sudo cp /etc/mysql/my.cnf /etc/mysql/my.cnf.og
    fi
}


function mysql_clean_db {
	mysql -u $DB_USER -e "REVOKE ALL on ${DB_WORDPRESS_NAME}.* from $DB_WORDPRESS_USER@localhost;"
	mysql -u $DB_USER -e "DELETE from mysql.user where User=\"$DB_WORDPRESS_USER\";"
	mysql -u $DB_USER -e "DROP DATABASE $DB_WORDPRESS_NAME;"
    mysql -u $DB_USER -e "FLUSH PRIVILEGES;"
}

## remove php
function php_remove {
    sudo apt-get remove -y php${PHP_VERSION} libapache2-mod-php${PHP_VERSION} php${PHP_VERSION}-mcrypt
    sudo apt-get remove -y php${PHP_VERSION}-gd php${PHP_VERSION}-curl libssh2-php
    sudo apt-get remove -y php${PHP_VERSION}-cli
    sudo apt-get remove -y php${PHP_VERSION}-mysqlnd-ms
}

function php5_config_remove {
	sudo mv /etc/php5/apache2/php.ini.bk /etc/php5/apache2/php.ini
	sudo mv /etc/apache2/mods-enabled/dir.conf.bk /etc/apache2/mods-enabled/dir.conf
    sudo service apache2 restart
    sudo a2enmod rewrite
    
}
function php5X_config_remove {
	sudo mv /etc/php/${PHP_VERSION}/apache2/php.ini.bk /etc/php/${PHP_VERSION}/apache2/php.ini
	sudo mv /etc/apache2/mods-enabled/dir.conf.bk /etc/apache2/mods-enabled/dir.conf
    sudo service apache2 restart
    sudo a2enmod rewrite
    
}



# download wordpress
function wordpress_content_remove {
    cd /var/www/html
	sudo rm -rf *
}

#end_remove
#mysql_clean_db
#mysql_remove
#php5X_config_remove
#php5_remove
#apache_remove
wordpress_content_remove
end_remove
