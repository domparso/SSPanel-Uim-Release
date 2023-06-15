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

ENV_FILE=docker/.env
ENV_PARAMS=

# APP在宿主机上目录
NGINX_WWW_PATH=
NGINX_CONF_PATH=
NGINX_SSL_PATH=

APP_HOME=
DOMAIN=
EMAIL=
PROTOCOL=

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
		$InstallMethod install python3 python3-dev python3-pip curl -y >/dev/null 2>&1
	elif [ "$is_redhat" == 1 ]; then
		echo -e "${Font_Green}Installing python3-utils ${Font_Suffix}"
		$InstallMethod install python3 python3-dev python3-pip curl -y >/dev/null 2>&1
	elif [ "$is_termux" == 1 ]; then
		echo -e "${Font_Green}Installing python3 ${Font_Suffix}"
		$InstallMethod install python3 python3-dev python3-pip curl -y >/dev/null 2>&1
	elif [ "$is_macos" == 1 ]; then
		echo -e "${Font_Green}Installing python3 ${Font_Suffix}"
		$InstallMethod install python python-dev python-pip curl
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

fail2ban(){
	apt-get install fail2ban \
	&& mv /etc/fail2ban/jail.conf jail.conf.bak \
	&& cp jail.conf /etc/fail2ban/jail.conf \
	&& systemctl restart fail2ban
}

install() {
	if ! command -v docker &>/dev/null; then
		curl -fsSL https://get.docker.com/ | sh \
		&& systemctl start docker
	fi
	
	if ! command -v docker-compose &>/dev/null; then
		python3 -m pip install docker-compose
	fi
	
	checkENVFile ${ENV_FILE}
	for i in ${ENV_PARAMS[@]};
	do
		tmp=$(echo ${i} | sed 's/{//g' | sed 's/}//g')
		arr1=(`echo $tmp | tr ':-' ' '`)
#		echo ${#arr1[@]} ${arr1[@]} 
#		echo ${arr1[0]} ${arr1[1]}
		if [[ "${arr1[0]}" =~ "NGINX_WWW_PATH" ]]; then
			NGINX_WWW_PATH=${arr1[1]}
		elif [[ "${arr1[0]}" =~ "NGINX_CONF_PATH" ]]; then
			NGINX_CONF_PATH=${arr1[1]}
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
	
	if [[ ! -d ${NGINX_CONF_PATH} ]]; then
		mkdir -p ${NGINX_CONF_PATH}
	fi
	
	if [[ ! -d ${NGINX_SSL_PATH} ]]; then
		mkdir -p ${NGINX_SSL_PATH}
	fi
	
	if [[ ! -d ${NGINX_WWW_PATH}/${APP_HOME} ]]; then
		mkdir -p ${NGINX_WWW_PATH}/${APP_HOME}
	fi
	
	if [[ "$PROTOCOL" = "https" ]]; then
		if [[ -d ${NGINX_SSL_PATH} ]]; then
			rm -rf ${NGINX_SSL_PATH}
		fi
		
		curl https://get.acme.sh | sh -s email=$EMAIL \
		&& acme.sh --issue --standalone -d $DOMAIN \
		ln -s /root/.acme.sh/${DOMAIN}_ecc ${NGINX_SSL_PATH} \
		&& sed -i "s/example.com/$DOMAIN/g" docker/443.conf \
		&& cp docker/443.conf ${NGINX_CONF_PATH}/default.conf
	else
		sed -i -e "s/example.com/$DOMAIN/g" docker/80.conf \
		&& cp docker/80.conf ${NGINX_CONF_PATH}/default.conf
	fi
	
	cd docker \
	&& docker-compose up -d
}

main() {
	checkOS
	checkDependencies
	install
	# fail2ban
}

main