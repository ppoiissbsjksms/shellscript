#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
export PATH

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

[[ $EUID -ne 0 ]] && echo -e "[${red}Error${plain}] This script must be run as root!" && exit 1

check_sys() {
    local checkType=$1
    local value=$2

    local release=''
    local systemPackage=''

    if [ -f /etc/redhat-release ]; then
        release="centos"
        systemPackage="yum"
    elif cat /etc/issue | grep -Eqi "debian"; then
        release="debian"
        systemPackage="apt"
    elif cat /etc/issue | grep -Eqi "ubuntu"; then
        release="ubuntu"
        systemPackage="apt"
    elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
        release="centos"
        systemPackage="yum"
    elif cat /proc/version | grep -Eqi "debian"; then
        release="debian"
        systemPackage="apt"
    elif cat /proc/version | grep -Eqi "ubuntu"; then
        release="ubuntu"
        systemPackage="apt"
    elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
        release="centos"
        systemPackage="yum"
    fi

    if [ ${checkType} == "sysRelease" ]; then
        if [ "$value" == "$release" ]; then
            return 0
        else
            return 1
        fi
    elif [ ${checkType} == "packageManager" ]; then
        if [ "$value" == "$systemPackage" ]; then
            return 0
        else
            return 1
        fi
    fi
}

version_ge(){
    test "$(echo "$@" | tr " " "\n" | sort -rV | head -n 1)" == "$1"
}

version_gt(){
    test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" != "$1"
}

getversion() {
    if [[ -s /etc/redhat-release ]]; then
        grep -oE  "[0-9.]+" /etc/redhat-release
    else
        grep -oE  "[0-9.]+" /etc/issue
    fi
}

centosversion() {
    if check_sys sysRelease centos; then
        local code=$1
        local version="$(getversion)"
        local main_ver=${version%%.*}
        if [ "$main_ver" == "$code" ]; then
            return 0
        else
            return 1
        fi
    else
        return 1
    fi
}

get_ip() {
    local IP=$( ip addr | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | egrep -v "^192\.168|^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-2]\.|^10\.|^127\.|^255\.|^0\." | head -n 1 )
    [ -z ${IP} ] && IP=$( wget -qO- -t1 -T2 ipv4.icanhazip.com )
    [ -z ${IP} ] && IP=$( wget -qO- -t1 -T2 ipinfo.io/ip )
    [ ! -z ${IP} ] && echo ${IP} || echo
}

xmrig_proxy_set(){
    while true
    do
    echo  "在脚本中配置完成矿池的coin:"
    for ((i=1;i<=${#coin[@]};i++ )); do
        hint="${coin[$i-1]}"
        echo -e "${green}${i}${plain}) ${hint}"
    done
    read -p "请输入一个数字 (默认直接回车将手动输入矿池信息):" selected
    [ -z "${selected}" ] && selected="diy"
    case "${selected}" in
        diy|1|2|3)
        echo "正在将挖掘币种切换为：${coin[${selected}-1]}"
        break
        ;;
        *)
        echo -e "[${red}Error${plain}] 请输入一个数字 [1-2]"
        ;;
    esac
    done

    if [ ! -e ${config} ]; then
            echo -e "[${red}Error${plain}] xmrig-proxy配置文件不存在，请修改路径。"
            echo
            exit 1
    fi

    if   [ "${selected}" == "diy" ]; then
      echo "请输入币名称："
      read -p "(Default: etn):" coindiy
      [ -z "${coindiy}" ] && coindiy="etn"
      echo
      echo "coin = ${coindiy}"
      echo
      echo "请输矿池地址及端口："
      read -p "(Default: etn-asia1.nanopool.org:13333):" urldiy
      [ -z "${urldiy}" ] && urldiy="etn-asia1.nanopool.org:13333"
      echo
      echo "url = ${urldiy}"
      echo
      echo "请输入钱包地址："
      read -p "(Default: etnjvSNXD6G3DmR3Kw1HFXAyEeZxUvCeR4LAyWWENcS2Ag3jwJ1MeRJPFiCPVB16WaeTYFUrxWRBYHSYhqZpbemX5CgA3iX2ff):" userdiy
      [ -z "${userdiy}" ] && userdiy="etnjvSNXD6G3DmR3Kw1HFXAyEeZxUvCeR4LAyWWENcS2Ag3jwJ1MeRJPFiCPVB16WaeTYFUrxWRBYHSYhqZpbemX5CgA3iX2ff"
      echo
      echo "user = ${userdiy}"
      echo
      echo "请输入矿池密码："
      read -p "(Default: x):" passdiy
      [ -z "${passdiy}" ] && passdiy="x"
      echo
      echo "pass = ${passdiy}"
      echo
      sed -i "s/\"coin\":.*/\"coin\": \"${coindiy}\"/" ${config}
      sed -i "s/\"url\":.*/\"url\": \"${urldiy}\"/" ${config}
      sed -i "s/\"user\":.*/\"user\": \"${userdiy}\"/" ${config}
      sed -i "s/\"pass\":.*/\"pass\": \"${passdiy}\"/" ${config}
    elif [ "${selected}" == "1" ]; then
      sed -i "s/\"coin\":.*/\"coin\": \"${coin1}\"/" ${config}
      sed -i "s/\"url\":.*/\"url\": \"${url1}\"/" ${config}
      sed -i "s/\"user\":.*/\"user\": \"${user1}\"/" ${config}
      sed -i "s/\"pass\":.*/\"pass\": \"${pass1}\"/" ${config}
    elif [ "${selected}" == "2" ]; then
      sed -i "s/\"coin\":.*/\"coin\": \"${coin2}\"/" ${config}
      sed -i "s/\"url\":.*/\"url\": \"${url2}\"/" ${config}
      sed -i "s/\"user\":.*/\"user\": \"${user2}\"/" ${config}
      sed -i "s/\"pass\":.*/\"pass\": \"${pass2}\"/" ${config}
    elif [ "${selected}" == "3" ]; then
      sed -i "s/\"coin\":.*/\"coin\": \"${coin3}\"/" ${config}
      sed -i "s/\"url\":.*/\"url\": \"${url3}\"/" ${config}
      sed -i "s/\"user\":.*/\"user\": \"${user3}\"/" ${config}
      sed -i "s/\"pass\":.*/\"pass\": \"${pass3}\"/" ${config}
    fi
    port=`cat ${config} | grep -A 1 bind | grep -v bind | awk -F '"' '{print $2}' | awk -F ':' '{print $2}'`
    echo -e "${green}${coin[${selected}-1]}${plain}矿池信息修改成功!"
	echo -e "代理地址    : $(get_ip)${plain}"
	echo -e "代理端口    : ${port}${plain}"
    echo 
}

xmrig_proxy_restart() {
    if check_sys packageManager yum; then
        if centosversion 6; then
            service xmrig-proxy restart || /etc/init.d/xmrig-proxy restart
        elif centosversion 7; then
            systemctl restart xmrig-proxy
        fi
    elif check_sys packageManager apt; then
        service xmrig-proxy restart || /etc/init.d/xmrig-proxy restart
    fi
    if [ $? -eq 0 ]; then
        echo -e "${green}xmrig-proxy重新加载成功！"
    else
        echo -e "[${red}Error${plain}] xmrig-proxy启动服务失败，请手动重载xmrig-proxy，或添加xmrig-proxy启动脚本！"
    fi
}

# 手动配置部分开始

# 配置文件路径
config=/root/xmrig-proxy/build/config.json
# 币（顺序要和下面的配置对应）
coin=(xmr etn)
# 顺序为1的矿池信息
coin1="xmr"
url1="xmr-asia1.nanopool.org:14444"
user1="44rugoDVTkhgtZnm6sLAxiXSAy9fwSP1H55hd2DeG9YPNqqDPVe8PdcjXqrT3anyZ22j7DEE74GkbVcQFyH2nNiC3hkE1bw"
pass1="x"
# 顺序为2的矿池信息
coin2="etn"
url2="etn-asia1.nanopool.org:13333"
user2="etnjvSNXD6G3DmR3Kw1HFXAyEeZxUvCeR4LAyWWENcS2Ag3jwJ1MeRJPFiCPVB16WaeTYFUrxWRBYHSYhqZpbemX5CgA3iX2ff"
pass2="x"
# 顺序为3的矿池信息
coin3=""
url3=""
user3=""
pass3=""

# 手动配置部分结束

xmrig_proxy_set
xmrig_proxy_restart
