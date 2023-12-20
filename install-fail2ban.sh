#!/bin/bash


CUR_DIR=$(cd "$(dirname "$0")";pwd)
ENV_FILE=docker/.env
SSHD_PORT=22

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
		echo -e "${Font_Green}Installing fail2ban ${Font_Suffix}"
		$InstallMethod install fail2ban -y >/dev/null 2>&1
	elif [ "$is_redhat" == 1 ]; then
		echo -e "${Font_Green}Installing fail2ban ${Font_Suffix}"
		$InstallMethod install fail2ban -y >/dev/null 2>&1
	elif [ "$is_termux" == 1 ]; then
		echo -e "${Font_Green}Installing fail2ban ${Font_Suffix}"
		$InstallMethod install fail2ban -y >/dev/null 2>&1
	elif [ "$is_macos" == 1 ]; then
		echo -e "${Font_Green}Installing fail2ban ${Font_Suffix}"
		$InstallMethod install fail2ban
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

install() {

	checkENVFile ${CUR_DIR}/${ENV_FILE}
	for i in ${ENV_PARAMS[@]};
	do
		tmp=$(echo ${i} | sed 's/{//g' | sed 's/}//g')
		arr1=(`echo $tmp | tr ':-' ' '`)
	#	echo ${#arr1[@]} ${arr1[@]}
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
		fi
	done

	if [[ -n "${SSHD_PORT}" && "${SSHD_PORT}" != "22" ]]; then
		echo sed -i -e "s#port     = ssh#port     = ${SSHD_PORT}#g" ${CUR_DIR}/jail/jail.conf
	fi

	cp ${CUR_DIR}/jail/jail.conf /etc/fail2ban/jail.local

	if [[ "${NGINX_LOG_PATH}" != "/var/log/nginx/logs" ]]; then
		echo sed -i -e "s#/var/log/nginx/logs#${NGINX_LOG_PATH}#g" ${CUR_DIR}/jail/jail.d/nginx.conf
	fi

	if [[ "${DB_LOG_PATH}" != "/var/log/mysql" ]]; then
		echo sed -i -e "s#/var/log/mysql#${DB_LOG_PATH}#g" ${CUR_DIR}/jail/jail.d/mysqld.conf
	fi

	cp ${CUR_DIR}/jail/jail.d/* /etc/fail2ban/jail.d
	cp ${CUR_DIR}/jail/filter.d/* /etc/fail2ban/filter.d
	cp ${CUR_DIR}/jail/action.d/* /etc/fail2ban/action.d

	
	if command -v systemctl &>/dev/null; then
		systemctl restart fail2ban
	else
		service fail2ban restart
	fi
}


main() {
	checkOS
	checkDependencies
	install

}

main
