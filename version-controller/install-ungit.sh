#!/bin/bash -x

# owner: Rajen
# email: rajen.lyz@gmail.com
# created_date: May 13th 2016
# updated_date: May 13th 2016
#               Jun 3rd 2016

# Prerequisites
#     TO Install: NVM, Node.js, NPM
#          NVM: Node version Manager, use it to install Node.js
#          Node.js: a JavaScript runtime
#          NPM: Node.js' package ecosystem, installed together with node.js

# Declare: 
#     nvm's installing get from : https://github.com/creationix/nvm

USER=`whoami`
MYPATH=`cat /etc/passwd|grep $USER|cut -d: -f 6`

IS_CURL=`dpkg -l|grep curl|grep ii|cut -d ' ' -f 3|grep -x curl`

if [[ "$EUID" -ne 0 ]]; then
    echo "Need run as root, ple try sudo..."
    exit 1
fi

#install curl
if [[ ! "$IS_CRUL" ]]; then
    sudo apt-get install -y curl
    if [[ "$?" -ne 0 ]]; then
        echo "Error: install curl failed..."
        exit 1
    fi
fi

# when use npm install ungit, it may need to connect to google...
cd /tmp
curl -o google.html https://www.google.com

if [[ ! -f google.html ]]; then
    echo "Warning: Connecting to google failed, it may lead to failure... "
    echo "         If so, ple check the network.... "
    exit 0
fi


#install nvm 
cd $MYPATH
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.31.1/install.sh | bash

# source nvm env vars
. /$MYPATH/.bashrc

# use nvm to install node.js
nvm install stable

# use npm to install ungit
npm install -g ungit
