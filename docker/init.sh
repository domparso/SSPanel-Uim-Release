#!/bin/bash


# set -e

APPHOME=/app
PHPPATH=/opt/bitnami/php/bin/php
BACKUPPATH=/opt/bitnami/backup


is_empty_dir(){ 
	return `ls -A $1|wc -w`
}

# copy php-fpm config
if is_empty_dir "/opt/bitnami/php/etc"; then
	cp -R /opt/bitnami/php/etc.default/* /opt/bitnami/php/etc/*
fi

# 创建网站目录

cd $APPHOME

if [[ "$REINSTALL" != "false" ]]; then
	# 备份
	if [[ "$REINSTALL" == "save" ]]; then
		rm -rf $BACKUPPATH/*
		cp -r config $BACKUPPATH/
		cp -r storage $BACKUPPATH/
		cp -r public/clients $BACKUPPATH/
	fi
	rm -rf *
	# 删除隐藏文件
	find /app -type d -name .\* | xargs rm -rf 
	find /app -type f -name .\* | xargs rm -rf 
fi

if [[ "`ls -A ${APPHOME}`" = "" ]]; then 
	echo "创建网站目录"
	
	if [[ $REPOVISI = "public" && -n $REPOURL ]]; then
		git clone --depth=1 -b $BRANCH $REPOURL .
	else
		tmp=(`echo $REPOURL | tr ':' ' '`)
		tmp1=`echo ${tmp[1]} | cut -b 3-`
		if [[ $GITREPO = "gitlab" && -n $TOKEN ]]; then
			# url=https://oauth2:${TOKEN}@${REPOURL}
			url=${tmp[0]} + ':' + "oauth2:${TOKEN}@" + tmp1
		else
			url=${tmp[0]} + ':' + "${TOKEN}@" + tmp1
		fi
		git clone --depth=1 -b $BRANCH $url .
	fi

	# git config core.filemode false \
	
	wget https://getcomposer.org/installer -O composer.phar \
	&& php composer.phar \
	&& php composer.phar install \
	&& chmod -R 777 * \
	&& cp config/.config.example.php config/.config.php \
	&& cp config/appprofile.example.php config/appprofile.php
	echo "创建网站目录完成"
	
	if [[ "$REINSTALL" == "save" ]]; then
		rm -rf ./config
		cp -r $BACKUPPATH/config ./
		cp -r $BACKUPPATH/storage/GeoLite2* ./storage/
		cp -r $BACKUPPATH/client ./public/
	else
		# write config
		echo "写入配置..."
		sed -i -e "s/$_ENV\['key'\]        = 'ChangeMe';/$_ENV['key']        = '$APPKEY';/g" \
		-e "s/$_ENV\['appName'\]    = 'SSPanel-UIM';/$_ENV['appName']    = '$APPNAME';/g" \
		-e "s|$_ENV\['baseUrl'\]    = 'https://example.com';|$_ENV['baseUrl']    = '$BASEURL';|g" \
		-e "s/$_ENV\['muKey'\]      = 'ChangeMe';/$_ENV['muKey']      = '$MUKEY';/g" \
		-e "s/$_ENV\['db_database'\]  = 'sspanel';/$_ENV['db_database']  = '$DB_DATABASE';/g" \
		-e "s/$_ENV\['db_username'\]  = 'root';/$_ENV['db_username']  = '$DB_USERNAME';/g" \
		-e "s/$_ENV\['db_password'\]  = 'sspanel';/$_ENV['db_password']  = '$DB_PASSWORD';/g" \
		-e "s/$_ENV\['db_charset'\]  = 'sspanel';/$_ENV['db_charset']  = '$DB_CHARACTER_SET';/g" \
		-e "s/$_ENV\['db_collation'\]  = 'sspanel';/$_ENV['db_collation']  = '$DB_COLLATE';/g" \
		config/.config.php

		if [[ -z "$DB_PORT" || "$DB_PORT" = "3306" ]]; then
			sed -i -e "s/$_ENV\['db_host'\]      = '';/$_ENV['db_host']      = '$DB_HOST';/g" config/.config.php
		else
			sed -i -e "s/$_ENV\['db_host'\]      = '';/$_ENV['db_host']      = '$DB_HOST:$DB_PORT';/g" config/.config.php
		fi
		
		if [[ -n $MAXMIND_LICENSE_KEY ]];then
			sed -i -e "s/$_ENV\['maxmind_license_key'\] = '';/$_ENV['maxmind_license_key'] = '$MAXMIND_LICENSE_KEY';/g" \
			config/.config.php
		fi
		
		echo "写入配置完成"
	fi

	# 站点初始化设置
	echo "站点初始化设置"

	if [[ $DBMODE = 'init' ]]; then
		echo "数据库初始化..."

		if [[ -f db/migrations/20000101000000_init_database.php.new ]]; then
			mv db/migrations/20000101000000_init_database.php.new db/migrations/20000101000000_init_database.php
			vendor/bin/phinx migrate
		else
			php xcat Migration new
		fi
	elif [[ $DBMODE = 'update' ]]; then
		echo "数据库更新..."
		
		php xcat Migration latest
		
		# if [[ -n $DBVERSION ]]; then
		# 	php xcat Migration $DBVERSION
		# else
		# 	php xcat Migration latest
		# fi
	fi

	php xcat Tool importAllSettings

	if [[ -n $ADMIN_MAIL && -n $ADMIN_PASSWORD ]]; then
		sh -c '/bin/echo -e "$ADMIN_MAIL\n$ADMIN_PASSWORD\ny\n" | php xcat Tool createAdmin'
	fi
	
	if [[ -n $MAXMIND_LICENSE_KEY ]];then
		 php xcat Update
	fi

	# 更新
	if [[ $BRANCH = "dev" ]]; then
		bash update.sh
	fi

	# 下载客户端
	if [[ $DOWNLOADCLIENT = "true" ]]; then
		php xcat ClientDownload
	fi
else
	echo "网站目录不为空"
fi


# 计划任务
echo "添加计划任务"
crontab -l > cron.tmp
echo "*/5 * * * * $PHPPATH $APPHOME/xcat  Cron" >> cron.tmp
echo "*/1 * * * * $PHPPATH $APPHOME/xcat  Job CheckJob" >> cron.tmp
echo "0 */1 * * * $PHPPATH $APPHOME/xcat  Job UserJob" >> cron.tmp
echo "0 0 * * * $PHPPATH -n $APPHOME/xcat Job DailyJob" >> cron.tmp

echo "5 0 * * * $PHPPATH $APPHOME/xcat FinanceMail day" >> cron.tmp
echo "6 0 * * 0 $PHPPATH $APPHOME/xcat FinanceMail week" >> cron.tmp
echo "7 0 1 * * $PHPPATH $APPHOME/xcat FinanceMail month" >> cron.tmp

echo "*/1 * * * * $PHPPATH $APPHOME/xcat DetectGFW" >> cron.tmp

crontab cron.tmp
rm cron.tmp

echo "站点初始化设置完成"

