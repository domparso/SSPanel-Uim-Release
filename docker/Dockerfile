# php-fpm 

ARG PHP_VERSION=8.2.1

FROM bitnami/php-fpm:$PHP_VERSION as base

LABEL \
	maintainer="Domparso <domparso@hotmail.com>" \
	org.opencontainers.image.authors="Domparso"

RUN apt-get update \
	&& apt-get install -y git wget bzip2 build-essential php7.4-dev libxml2 libxml2-dev \
	&& rm -rf /var/lib/apt/lists/*

# download php
RUN cd /tmp \
	&& wget https://www.php.net/distributions/php-8.2.1.tar.bz2 \
	&& tar -xvf php-8.2.1.tar.bz2

# php-bcmath
# RUN cd /tmp/php-8.2.1/ext/bcmath/ \
#   && phpize \
#   && ./configure --with-php-config=/opt/bitnami/php/bin/php-config \
#   && make && make install \
#   && echo "extension=bcmath" >> /opt/bitnami/php/etc/php.ini

# php-opcache
RUN cd /tmp/php-8.2.1/ext/opcache/ \
	&& phpize \
	&& ./configure --with-php-config=/opt/bitnami/php/bin/php-config \
	&& make && make install \
#	&& sed -i s@/;zend_extension=opcache/@/zend_extension=opcache/@g /opt/bitnami/php/etc/php.ini
#	&& echo "zend_extension=opcache" >> /opt/bitnami/php/etc/php.ini
	&& sed -i "s@;opcache.file_cache=@opcache.file_cache=/tmp@g" \
	-i "s@opcache.interned_strings_buffer = 8@opcache.interned_strings_buffer = 64\nopcache.jit=on\\nopcache.jit_buffer_size=256M@g" \
	-i "s@opcache.max_accelerated_files = 4000@opcache.max_accelerated_files = 65535@g" \
	-i "s@opcache.memory_consumption = 128@opcache.memory_consumption = 512@g" \
	-i "s@;opcache.validate_permission=0@opcache.validate_permission=on@g" \
	-i "s@;opcache.validate_root=0@opcache.validate_root=on@g" \
	/opt/bitnami/php/etc/php.ini

# php-xmlrpc
RUN cd /tmp \
	&& wget https://pecl.php.net/get/xmlrpc-1.0.0RC3.tgz \
	&& tar zxvf xmlrpc-1.0.0RC3.tgz \
	&& cd xmlrpc-1.0.0RC3 \
	&& phpize \
	&& ./configure --with-php-config=/opt/bitnami/php/bin/php-config \
	&& make && make install \
	&& echo "extension=xmlrpc" >> /opt/bitnami/php/etc/php.ini

# php-redis
RUN cd /tmp \
	&& wget https://pecl.php.net/get/redis-5.3.7.tgz \
	&& tar zxvf redis-5.3.7.tgz \
	&& cd redis-5.3.7 \
	&& phpize \
	&& ./configure --with-php-config=/opt/bitnami/php/bin/php-config \
	&& make && make install \
	&& echo "extension=redis.so" >> /opt/bitnami/php/etc/php.ini

# libyaml
RUN cd /tmp \
    && wget -O libyaml-0.2.5.tar.gz https://github.com/yaml/libyaml/archive/0.2.5.tar.gz \
    && tar zxvf libyaml-0.2.5.tar.gz \
    && cd libyaml-0.2.5 \
    && ./bootstrap \
    && ./configure \
    && make && make install

# yaml
RUN cd /tmp \
	&& wget https://pecl.php.net/get/yaml-2.2.3.tgz \
	&& tar xf yaml-2.2.3.tgz \
	&& cd yaml-2.2.3 \
	&& phpize \
	&& ./configure --with-php-config=/opt/bitnami/php/bin/php-config \
	&& make && make install \
	&& echo "extension=yaml" >> /opt/bitnami/php/etc/php.ini

# 禁用一些危险的 PHP Function
RUN sed -i 's@^disable_functions.*@disable_functions = passthru,exec,system,chroot,chgrp,chown,shell_exec,proc_open,proc_get_status,ini_alter,ini_restore,dl,readlink,symlink,popepassthru,stream_socket_server,fsocket,popen@' /opt/bitnami/php/etc/php.ini \
	sed -i 's@^disable_functions.*@disable_functions = passthru,exec,system,chroot,chgrp,chown,shell_exec,proc_open,proc_get_status,ini_alter,ini_restore,dl,readlink,symlink,popepassthru,stream_socket_server,fsocket,popen@' /opt/bitnami/php/etc/php.ini


FROM bitnami/php-fpm:$PHP_VERSION 

RUN apt-get update \
	&& apt-get install -y git unzip wget cron systemctl rsyslog xz-utils \
	&& rm -rf /var/lib/apt/lists/*

# 时间同步
RUN cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

# 开启cron日志
# RUN sed -i s@/#cron.*/@/cron.*/@g /etc/rsyslog.conf

COPY --from=base /opt/bitnami /opt/bitnami
COPY --from=base /opt/bitnami/php/etc /opt/bitnami/php/etc.default
COPY --from=base /usr/local/lib/libyaml* /usr/local/lib/

COPY init.sh /usr/local/bin/init.sh
RUN chmod +x /usr/local/bin/init.sh

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
