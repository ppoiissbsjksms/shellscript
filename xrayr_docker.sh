#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}错误：${plain} 必须使用root用户运行此脚本！\n" && exit 1

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
    echo -e "${red}未检测到系统版本，请联系脚本作者！${plain}\n" && exit 1
fi

if [ "$(getconf WORD_BIT)" != '32' ] && [ "$(getconf LONG_BIT)" != '64' ] ; then
    echo "${red}未本软件不支持 32 位系统(x86)，请使用 64 位系统(x86_64)，如果检测有误，请联系作者${plain}\n"
    exit 2
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
        echo -e "${red}请使用 CentOS 7 或更高版本的系统！${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"ubuntu" ]]; then
    if [[ ${os_version} -lt 16 ]]; then
        echo -e "${red}请使用 Ubuntu 16 或更高版本的系统！${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"debian" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red}请使用 Debian 8 或更高版本的系统！${plain}\n" && exit 1
    fi
fi

install_dep(){
        if [[ x"${release}" == x"centos" ]]; then
            yum clean all
            yum makecache
            if [ ${os_version} -eq 7 ]; then
                yum install epel-release -y
                yum install wget curl unzip tar crontabs socat yum-utils ca-certificates -y
            elif [ ${os_version} -eq 8 ]; then
                dnf -y install epel-release
                dnf -y install wget curl unzip tar crontabs socat ca-certificates
            fi
        elif [[ x"${release}" == x"ubuntu" ]]; then
            apt update -y
            apt install -y wget curl unzip tar crontabs socat yum-utils apt-transport-https ca-certificates gnupg lsb-release
        elif [[ x"${release}" == x"debian" ]]; then
            apt update -y
            apt install -y wget curl unzip tar crontabs socat yum-utils apt-transport-https ca-certificates gnupg lsb-release
        fi
}

install_docker() {
    if [[ ! `command -v docker` ]]; then
        if [[ x"${release}" == x"centos" ]]; then
            yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            yum install docker-ce docker-ce-cli containerd.io -y
            systemctl enable docker --now
        elif [[ x"${release}" == x"ubuntu" ]]; then
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
            echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            apt-get update -y
            apt-get install docker-ce docker-ce-cli containerd.io -y
            systemctl enable docker --now
        elif [[ x"${release}" == x"debian" ]]; then
            curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
            echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            apt-get update -y
            apt-get install docker-ce docker-ce-cli containerd.io -y
            systemctl enable docker --now
        fi
    fi
}

install_XrayR() {
    apidomain=$(awk -F[/:] '{print $4}' <<< ${apihost})
    xrayrname=${apidomain}_${nodetype}_${nodeid}
    docker ps | grep -wq "xrayr_${xrayrname}"
    if [[ $? -eq 0 ]]; then
        docker rm -f xrayr_${xrayrname}
    fi
    [ -e /opt/xrayr ] || mkdir -p /opt/xrayr/
    wget -N --no-check-certificate -O /opt/xrayr/config_${xrayrname}.yml https://raw.githubusercontent.com/XrayR-project/XrayR/master/main/config.yml.example
    wget -N --no-check-certificate -O /opt/xrayr/dns_${xrayrname}.json https://raw.githubusercontent.com/XrayR-project/XrayR/master/main/dns.json
    if [[ $? -ne 0 ]]; then
        echo -e "${red}下载失败，请确保你的服务器能够下载 Github 的文件${plain}"
        exit 1
    fi
    sed -i "s/\"SSpanel\"/\"${paneltype}\"/" /opt/xrayr/config_${xrayrname}.yml
    sed -i "s?http://127.0.0.1:667?${apihost}?" /opt/xrayr/config_${xrayrname}.yml
    sed -i "s/123/${apikey}/" /opt/xrayr/config_${xrayrname}.yml
    sed -i "s/41/${nodeid}/" /opt/xrayr/config_${xrayrname}.yml
    sed -i "s/NodeType: V2ray/NodeType: ${nodetype}/" /opt/xrayr/config_${xrayrname}.yml
    sed -i "s/CertMode: dns/CertMode: ${certmode}/" /opt/xrayr/config_${xrayrname}.yml
    docker pull crackair/xrayr:latest
    docker run --restart=always --name xrayr_${xrayrname} -d -v /opt/xrayr/config_${xrayrname}.yml:/etc/XrayR/config.yml -v /opt/xrayr/dns_${xrayrname}.json:/etc/XrayR/dns.json --network=host crackair/xrayr:latest
    docker ps | grep -wq "xrayr_${xrayrname}"
    if [[ $? -eq 0 ]]; then
        crontab -l > /tmp/cronconf
        if grep -wq "xrayr_${xrayrname}" /tmp/cronconf;then
            sed -i "/xrayr_${xrayrname}/d" /tmp/cronconf
        fi
        echo "3 6 * * *  docker restart xrayr_${xrayrname}" >> /tmp/cronconf
        crontab /tmp/cronconf
        rm -f /tmp/cronconf
        echo -e "${green}已添加定时任务：每天6点3分重启节点[${nodeid}]${plain}"
        crontab -l | grep -w "xrayr_${xrayrname}"
        echo -e "${green}节点[${nodeid}]安装完成${plain}"
        echo -e "${green}如无法使用，输入命令查看日志：docker logs xrayr_${xrayrname} ${plain}"
        docker ps
    fi
}

hello(){
    echo ""
    echo -e "${yellow}XrayR Docker版一键安装脚本，支持节点多开${plain}"
    echo -e "${yellow}支持系统:  CentOS 7+, Debian8+, Ubuntu16+${plain}"
    echo ""
}

help(){
    hello
    echo "使用示例：bash $0 -p SSpanel -w http://www.domain.com:80 -k apikey -i 10 -t V2ray"
    echo ""
    echo "  -h     显示帮助信息"
    echo "  -p     【必填】指定前端面板类型，默认为SSpanel，可选：SSPanel,V2board,PMpanel,Proxypanel"
    echo "  -w     【必填】指定WebApi地址，例：http://www.domain.com:80"
    echo "  -k     【必填】指定WebApikey"
    echo "  -i     【必填】指定节点ID"
    echo "  -t     【选填】指定节点类型，默认为V2ray，可选：V2ray, Shadowsocks, Trojan"
    echo "目前仅支持上述参数设定，其他参数将保持默认，暂不支持tls模式"
    echo ""
}

apihost=www.domain.com
apikey=demokey
nodeid=demoid
certmode=none

# -p PanelType
# -w webApiHost
# -k webApiKey
# -i NodeID
# -t NodeType
# -m CertMode
# -d CertDomain
# -e Email
# -e1 DNSEnv
# -e2 DNSEnv
# -h help
if [[ $# -eq 0 ]];then
    help
    exit 1
fi
while getopts ":p:w:k:i:t:h" optname
do
    case "$optname" in
      "p")
        paneltype=$OPTARG
        ;;
      "w")
        apihost=$OPTARG
        ;;
      "k")
        apikey=$OPTARG
        ;;
      "i")
        nodeid=$OPTARG
        ;;
      "t")
        nodetype=$OPTARG
        ;;
      "h")
        help
        exit 0
        ;;
      ":")
        echo "$OPTARG 选项没有参数值"
        ;;
      "?")
        echo "$OPTARG 选项未知"
        ;;
      *)
        help
        exit 1
        ;;
    esac
done

echo -e "${green}您输入的参数：${plain}"
if [[ x"${apihost}" == x"www.domain.com" ]]; then
    echo -e "${red}未输入 -w 选项，请重新运行${plain}"
    exit 1
else
    echo -e "${yellow}前端面板地址：${apihost}${plain}"
fi
if [[ x"${paneltype}" == x ]]; then
    echo -e "${red}前端面板类型：SSpanel (未指定默认使用该值)${plain}"
    paneltype=SSpanel
else
    echo -e "${yellow}前端面板类型：${paneltype}${plain}"
fi
if [[ x"${apikey}" == x"demokey" ]]; then
    echo -e "${red}未输入 -k 选项，请重新运行${plain}"
    exit 1
else
    echo -e "${yellow}前端通讯秘钥：${apikey}${plain}"
fi
if [[ x"${nodeid}" == x"demoid" ]]; then
    echo -e "${red}未输入 -i 选项，请重新运行${plain}"
    exit 1
else
    echo -e "${yellow}节点ID：${nodeid}${plain}"
fi
if [[ x"${nodetype}" == x ]]; then
    echo -e "${red}节点类型：V2ray(未指定默认使用该值)${plain}"
    nodetype=V2ray
else
    echo -e "${yellow}节点类型：${nodetype}${plain}"
fi
if [[ ! "${nodeid}" =~ ^[0-9]+$ ]]; then   
    echo -e "${red}-i 选项参数值仅限数字格式，请输入正确的参数值并重新运行${plain}"
    exit 1
fi 

echo -e "${green}即将开始安装，取消请按Ctrl+C${plain}"
sleep 10
install_dep
install_docker
install_XrayR
