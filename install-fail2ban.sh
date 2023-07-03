#!/bin/bash


CUR_DIR=$(cd "$(dirname "$0")";pwd)/jail

NGINX_LOG_PATH=/usr/share/nginx/LOG

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

install() {

	if [[ "${NGINX_LOG_PATH}" = "/usr/share/nginx/logs" ]]; then
		echo sed -i -e "s#/usr/share/nginx/logs#${NGINX_LOG_PATH}#g" ${CUR_DIR}/jail.d/nginx.conf
	fi

	cp ${CUR_DIR}/jail.d/* /etc/fail2ban/jail.d
	cp ${CUR_DIR}/filter.d/* /etc/fail2ban/filter.d
	
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
