#!/bin/bash -x

# owner: Rajen
# email: rajen.lyz@gmail.com
# created_time: May 13th 2016
# updated_time: May 13th 2016

# Claim: the install guide is got from : 
#        https://github.com/robbyrussell/oh-my-zsh

# prerequisites
#     have installed 'curl' and zsh

# need to be run as root
if [[ $EUID -ne 0 ]]; then
    echo "Need to be run as root..."
    exit 1
fi

sudo apt-get install -y curl
sudo apt-get install --force-yes -y zsh zsh-common

if [[ "$?" -ne 0 ]]; then
    echo "Error for the precious execution "
    exit 1
else
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
fi
