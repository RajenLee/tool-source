#!/bin/bash

#brief: install sublime text 3
#auther: rajen
#email: rajen@rajen.info
#create: Feb 15th 2017
#update: Feb 15th 2017

# Note: need test

if [ $EUID != 0 ]; then
    echo " Must run with root role ... "
    exit 1
fi

SUBLIME_PKG="sublime.deb"

# download and install sublime package
$(wget -O $SUBLIME_PKG https://download.sublimetext.com/sublime-text_build-3126_amd64.deb)

sudo dpkg -i $SUBLIME_PKG

# download package_controller
$(wget https://packagecontrol.io/Package%20Control.sublime-package)

mkdir -p ~/.config/sublime-text-3/Packages/

cp Package\ Control.sublime-package ~/.config/sublime-text-3/Packages/

rm -f $SUBLIME_PKG
rm -f "Package\ Control.sublime-package"

