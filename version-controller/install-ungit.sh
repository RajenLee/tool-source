#!/bin/bash -x

# owner: Rajen
# email: rajen.lyz@gmail.com
# created_date: May 13th 2016
# updated_date: May 13th 2016

# Declare: 

# Prerequisites
#     need install: nodejs, npm

USER=`whoami`
MYPATH=`cat /etc/passwd|grep $USER|cut -d: -f 6`

IS_CURL=`dpkg -l|grep curl|grep ii|cut -d ' ' -f 3|grep -x curl`

#install curl
if [[ ! "$IS_CRUL" ]]; then
	#sudo apt-get install -y curl
    echo "===install curl===$?"
    if [[ "$?" -ne 0 ]]; then
        echo "Error: install curl failed..."
        exit 1
    fi
fi

# when use npm install ungit, it may need to connect to google...
cd /tmp
curl -o google.html https://www.google.com

if [[ ! -f google.html ]]; then
    echo "Warning: Connect to google failed, if installing ungit failed, "
    echo "         ple check the network.... "
    exit 0
fi


#install nvm
cd $MYPATH
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.31.1/install.sh | bash

nvm install stable

npm install -g ungit
