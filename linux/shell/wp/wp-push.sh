#!/bin/bash
set -xe
cd /root/.wordpress
find . -mtime +30 -exec rm -rf {} \;
git add .
git add -A
git commit -m "update"
git push origin master
