#!/bin/bash

shopt -s expand_aliases
Font_Black="\033[30m"
Font_Red="\033[31m"
Font_Green="\033[32m"
Font_Yellow="\033[33m"
Font_Blue="\033[34m"
Font_Purple="\033[35m"
Font_SkyBlue="\033[36m"
Font_White="\033[37m"
Font_Suffix="\033[0m"

CUR_DIR=$(cd "$(dirname "$0")";pwd)
ENV_FILE=docker/.env
ENV_PARAMS=

# APP在宿主机上目录
NGINX_WWW_PATH=
NGINX_CONF_PATH=
NGINX_LOG_PATH=
NGINX_SSL_PATH=

REINSTALL=
APP_HOME=
DOMAIN=
EMAIL=
PROTOCOL=

ACME_PATH=~/.acme.sh

resolver=8.8.8.8

TZ=Asia/Shanghai

checkOS() {
    ifTermux=$(echo $PWD | grep termux)
    ifMacOS=$(uname -a | grep Darwin)
    if [ -n "$ifTermux" ]; then
        os_version=Termux
        is_termux=1
    elif [ -n "$ifMacOS" ]; then
        os_version=MacOS
        is_macos=1
    else
        os_version=$(grep 'VERSION_ID' /etc/os-release | cut -d '"' -f 2 | tr -d '.')
    fi

    if [[ "$os_version" == "2004" ]] || [[ "$os_version" == "10" ]] || [[ "$os_version" == "11" ]]; then
        is_windows=1
        ssll="-k --ciphers DEFAULT@SECLEVEL=1"
    fi

    if [ "$(which apt 2>/dev/null)" ]; then
        InstallMethod="apt"
        is_debian=1
    elif [ "$(which dnf 2>/dev/null)" ] || [ "$(which yum 2>/dev/null)" ]; then
        InstallMethod="yum"
        is_redhat=1
    elif [[ "$os_version" == "Termux" ]]; then
        InstallMethod="pkg"
    elif [[ "$os_version" == "MacOS" ]]; then
        InstallMethod="brew"
    fi
}

checkDependencies() {

    # os_detail=$(cat /etc/os-release 2> /dev/null)
	
	if [ "$is_debian" == 1 ]; then
		echo -e "${Font_Green} update ${Font_Suffix}"
		$InstallMethod update >/dev/null 2>&1
	elif [ "$is_redhat" == 1 ]; then
		echo -e "${Font_Green} update ${Font_Suffix}"
		if [[ "$os_version" -gt 7 ]]; then
			$InstallMethod makecache >/dev/null 2>&1
		else
			$InstallMethod makecache >/dev/null 2>&1
		fi
	elif [ "$is_termux" == 1 ]; then
		echo -e "${Font_Green} update ${Font_Suffix}"
		$InstallMethod update -y >/dev/null 2>&1
	elif [ "$is_macos" == 1 ]; then
		echo -e "${Font_Green} update ${Font_Suffix}"
	fi

	if [ "$is_debian" == 1 ]; then
		echo -e "${Font_Green}Installing python3-utils ${Font_Suffix}"
		$InstallMethod install python3 python3-dev python3-pip curl socat -y >/dev/null 2>&1
	elif [ "$is_redhat" == 1 ]; then
		echo -e "${Font_Green}Installing python3-utils ${Font_Suffix}"
		$InstallMethod install python3 python3-dev python3-pip curl socat -y >/dev/null 2>&1
	elif [ "$is_termux" == 1 ]; then
		echo -e "${Font_Green}Installing python3 ${Font_Suffix}"
		$InstallMethod install python3 python3-dev python3-pip curl socat -y >/dev/null 2>&1
	elif [ "$is_macos" == 1 ]; then
		echo -e "${Font_Green}Installing python3 ${Font_Suffix}"
		$InstallMethod install python python-dev python-pip curl socat
	fi
}

checkENVFile() {
	local s='[[:space:]]*' s1='[[:space:]]' w='[a-zA-Z0-9_:-]*' fs=$(echo @|tr @ '\034')
	result=`sed -ne "s|^\($s\):|\1|" \
		-e "s|^\($s\)\($w\)$s=$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
		-e "s|^\($s\)\($w\)$s=$s\"{\($w\)}$s\"|\1$fs\2$fs\3|p" $1 |
	awk -F$fs '{
		indent = length($1)/2;
		vname[indent] = $2;
		for (i in vname) {
			if (i > indent) {
				delete vname[i]
			}
		}
		# printf("%s=\"%s\"\n", $2, $3)
		printf("%s\n", $3)
	}'`
	
	ENV_PARAMS=(${result// /})
}

fail2ban() {
	apt-get install fail2ban \
	&& mv /etc/fail2ban/jail.conf jail.conf.bak \
	&& cp jail.conf /etc/fail2ban/jail.conf \
	&& systemctl restart fail2ban
}

isDirEmpty() {
	if [[ "$(ls -A $DIR)" ]]; then
		return true
	else
		return false
fi
}

getCer() {
	if [[ -d ${NGINX_SSL_PATH} ]]; then
		rm -rf ${NGINX_SSL_PATH}
	fi
	
	if [[ -d ~/.acme.sh ]]; then
		cd /root/.acme.sh
		
		if [[ -d ${DOMAIN} ]]; then
			mv ${DOMAIN}_ecc ${DOMAIN}_ecc.bak
		fi
	else
		curl https://get.acme.sh | sh -s email=${EMAIL} \
		&& cd /root/.acme.sh
	fi

	./acme.sh --register-account  --server letsencrypt -m ${EMAIL} \
	&& ./acme.sh --issue --standalone --server letsencrypt -d ${DOMAIN} --debug 2 \
	# && ./acme.sh --issue --standalone -d ${DOMAIN} --debug 2
	&& ln -s /root/.acme.sh/${DOMAIN}_ecc ${NGINX_SSL_PATH} \
	&& sed -i "s/example.com/${DOMAIN}/g" ${CUR_DIR}/docker/443.conf \
	&& cp ${CUR_DIR}/docker/443.conf ${NGINX_CONF_PATH}/sspanel.conf
}

install() {
	if ! command -v docker &>/dev/null; then
		curl -fsSL https://get.docker.com/ | sh \
		&& echo '{"data-root": "/home/docker", "dns": ["8.8.8.8","1.1.1.1"]}' >> /etc/docker/daemon.json \
		&& systemctl start docker
	fi
	
	if ! command -v docker-compose &>/dev/null; then
		python3 -m pip install docker-compose
	fi
	
	checkENVFile ${CUR_DIR}/${ENV_FILE}
	for i in ${ENV_PARAMS[@]};
	do
		tmp=$(echo ${i} | sed 's/{//g' | sed 's/}//g')
		arr1=(`echo $tmp | tr ':-' ' '`)
#		echo ${#arr1[@]} ${arr1[@]} 
#		echo ${arr1[0]} ${arr1[1]}
		if [[ "${arr1[0]}" =~ "REINSTALL" ]]; then
			REINSTALL=${arr1[1]}
		elif [[ "${arr1[0]}" =~ "DB_DATA_PATH" ]]; then
			DB_DATA_PATH=${arr1[1]}
		elif [[ "${arr1[0]}" =~ "DB_LOG_PATH" ]]; then
			DB_LOG_PATH=${arr1[1]}
		elif [[ "${arr1[0]}" =~ "NGINX_LOG_PATH" ]]; then
			NGINX_LOG_PATH=${arr1[1]}
		elif [[ "${arr1[0]}" =~ "NGINX_SSL_PATH" ]]; then
			NGINX_SSL_PATH=${arr1[1]}
		elif [[ "${arr1[0]}" =~ "APP_HOME" ]]; then
			APP_HOME=${arr1[1]}
		elif [[ "${arr1[0]}" =~ "DOMAIN" ]]; then
			DOMAIN=${arr1[1]}
		elif [[ "${arr1[0]}" =~ "ADMIN_MAIL" ]]; then
			EMAIL=${arr1[1]}
		elif [[ "${arr1[0]}" =~ "PROTOCOL" ]]; then
			PROTOCOL=${arr1[1]}
		fi
	done
	
	if [[ ${REINSTALL} = "false" ]]; then
		clear
	fi

	if [[ ! -d ${DB_DATA_PATH} ]]; then
  		mkdir -p ${DB_DATA_PATH}
  		chmod 777 ${DB_DATA_PATH}
  fi

  if [[ ! -d ${DB_LOG_PATH} ]]; then
  		mkdir -p ${DB_LOG_PATH}
  		chmod 777 ${DB_DATA_PATH}
  fi

	if [[ ! -d ${NGINX_CONF_PATH} ]]; then
		mkdir -p ${NGINX_CONF_PATH}
	fi
	
	if [[ ! -d ${NGINX_LOG_PATH} ]]; then
		mkdir -p ${NGINX_LOG_PATH}
	fi
	
	if [[ ! -d ${NGINX_WWW_PATH}/${APP_HOME} ]]; then
		mkdir -p ${NGINX_WWW_PATH}/${APP_HOME}
	fi
	
	if [[ "$PROTOCOL" = "https" ]]; then
		getCer
	else
		sed -i -e "s/example.com/$DOMAIN/g" docker/80.conf \
		&& cp docker/80.conf ${NGINX_CONF_PATH}/sspanel.conf
	fi
	
	cd ${CUR_DIR}/docker \
	&& docker-compose up -d \
	&& docker exec -it mariadb ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime \
	&& docker exec -it mariadb chmod 777 /opt/bitnami/mariadb/logs \
	&& docker exec -it nginx ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime \
	&& docker exec -it nginx chmod 777 /var/log/nginx \
	&& docker exec -it nginx sed -i "s@#gzip  on;@#gzip  on;\\n\\n    resolver 8.8.8.8;@g" /etc/nginx/nginx.conf \
	&& docker exec -it nginx nginx -s reload
}

clear() {
	rm -rf /root/.acme.sh
	rm -rf ${NGINX_CONF_PATH}
	rm -rf ${NGINX_LOG_PATH}
	rm -rf ${NGINX_WWW_PATH}
	rm -rf ${NGINX_SSL_PATH}
}

main() {
	checkOS
	checkDependencies
	install
	# fail2ban
}

main