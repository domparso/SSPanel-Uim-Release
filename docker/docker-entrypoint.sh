#!/bin/bash


set -e


if [ -f /usr/local/bin/init.sh ]; then
	/usr/local/bin/init.sh && mv /usr/local/bin/init.sh /usr/local/bin/init.sh.bak
fi

# start php-fpm: master process (/opt/bitnami/php/etc/php-fpm.conf)
# /opt/bitnami/php/sbin/php-fpm

systemctl start cron

php-fpm -F --pid /opt/bitnami/php/tmp/php-fpm.pid -y /opt/bitnami/php/etc/php-fpm.conf

