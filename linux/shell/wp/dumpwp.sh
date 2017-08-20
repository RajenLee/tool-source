#!/bin/bash

DATE=$(date "+%Y-%m-%d")
mysqldump -u root wordpress > /root/.wordpress/wordpress-${DATE}.sql
