#!/usr/bin/env bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}Error：${plain} Este script debe ejecutarse como root！\n" && exit 1

# check os
if [[ -f /etc/redhat-release ]]; then
    release="centos"
elif cat /etc/issue | grep -Eqi "debian"; then
    release="debian"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
elif cat /proc/version | grep -Eqi "debian"; then
    release="debian"
elif cat /proc/version | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
else
    echo -e "${red}No se detectó la versión del sistema, póngase en contacto con el autor del script！${plain}\n" && exit 1
fi

os_version=""

# os version
if [[ -f /etc/os-release ]]; then
    os_version=$(awk -F'[= ."]' '/VERSION_ID/{print $3}' /etc/os-release)
fi
if [[ -z "$os_version" && -f /etc/lsb-release ]]; then
    os_version=$(awk -F'[= ."]+' '/DISTRIB_RELEASE/{print $2}' /etc/lsb-release)
fi

if [[ x"${release}" == x"centos" ]]; then
    if [[ ${os_version} -le 6 ]]; then
        echo -e "${red}Utilice un sistema CentOS 7 o superior！${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"ubuntu" ]]; then
    if [[ ${os_version} -lt 16 ]]; then
        echo -e "${red}Utilice Ubuntu 16 o un sistema superior！${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"debian" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red}Utilice el sistema Debian 8 o superior！${plain}\n" && exit 1
    fi
fi

install_base() {
    if [[ x"${release}" == x"centos" ]]; then
        yum install wget curl tar -y
    else
        apt install wget curl tar -y
    fi
}

install_v2ray() {
    echo -e "${green}instalando v2ray${plain}"
    bash <(curl -L -s https://install.direct/go.sh)
    if [[ $? -ne 0 ]]; then
        echo -e "${red}La instalación o actualización de V2ray falló, verifique el mensaje de error${plain}"
        exit 1
    fi
    systemctl enable v2ray
    systemctl start v2ray
}

close_firewall() {
    if [[ x"${release}" == x"centos" ]]; then
        systemctl stop firewalld
        systemctl disable firewalld
    elif [[ x"${release}" == x"ubuntu" ]]; then
        ufw disable
    elif [[ x"${release}" == x"debian" ]]; then
        iptables -P INPUT ACCEPT
        iptables -P OUTPUT ACCEPT
        iptables -P FORWARD ACCEPT
        iptables -F
    fi
}

install_v2-ui() {
    systemctl stop v2-ui
    cd /usr/local/
    
    #sudo mkdir /usr/local/v2-ui
    #last_version=$(curl -Ls "https://api.github.com/repos/sprov065/v2-ui/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    #echo -e "Se detectó la última versión de v2ray-Panel：${last_version}，Comience la instalación"
    wget -N --no-check-certificate -O /usr/local/v2-ui-linux.tar.gz https://www.dropbox.com/s/1tuupyrw4w8qh3h/v2-ui-linux.gz
    if [[ $? -ne 0 ]]; then
        echo -e "${red}La descarga de v2-ui falló, asegúrese de que su servidor pueda descargar archivos Dropbox, si falla la instalación múltiple, consulte el tutorial de instalación manual${plain}"
        exit 1
    fi
    tar zxvf v2-ui-linux.tar.gz
    #mv /usr/local/v2-ui-linux/* /usr/local/v2-ui/
    rm v2-ui-linux.tar.gz -f
    sudo rm -rf /usr/local/v2-ui-linux
    cd v2-ui
    chmod +x v2-ui
    cp -f v2-ui.service /etc/systemd/system/
    systemctl daemon-reload
    systemctl enable v2-ui
    systemctl start v2-ui
    echo -e "${green}v2ray-Panel v${last_version}${plain} La instalación se completó, el panel se inició，"
    echo -e ""
    echo -e "Si se trata de una instalación nueva, el puerto web predeterminado es ${green}65432${plain}，Nombre de usuario y contraseña son por defecto ${green}admin${plain}"
    echo -e "Asegúrese de que este puerto no esté ocupado por otros programas.，${yellow}Y asegúrese de que se libere el puerto 65432.${plain}"
    echo -e ""
    echo -e "Si se trata de un panel de actualización, acceda al panel como lo hizo anteriormente."
    echo -e ""
    curl -o /usr/bin/v2-ui -Ls https://raw.githubusercontent.com/RomanHrbr/v2-ui/master/v2-ui.sh
    chmod +x /usr/bin/v2-ui
    echo -e "v2ray-panel Administrar el uso del script: "
    echo -e "------------------------------------------"
    echo -e "Mostrar menú de gestión (más funciones)"
    echo -e "v2ray-Panel start        - Inicie el panel"
    echo -e "v2ray-Panel stop         - Detener el panel"
    echo -e "v2ray-Panel restart      - Reinicie el panel"
    echo -e "v2ray-Panel status       - Ver el estado del panel"
    echo -e "v2ray-Panel enable       - Establecer el arranque desde panel"
    echo -e "v2ray-Panel disable      - Cancele el arranque desde el panel"
    echo -e "v2ray-Panel log          - Ver registros del panel"
    echo -e "v2ray-Panel update       - Actualizar el panel"
    echo -e "v2ray-Panel install      - Instalar el panel"
    echo -e "v2ray-Panel uninstall    - Desinstalar el panel"
    echo -e "------------------------------------------"
}

echo -e "${green}Comenzando la instalación${plain}"
install_base
install_v2ray
install_v2-ui
