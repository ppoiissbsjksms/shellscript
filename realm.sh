#!/usr/bin/env bash
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
stty erase ^?

cd "$(
  cd "$(dirname "$0")" || exit
  pwd
)" || exit

# 字体颜色配置
Green="\033[32m"
Red="\033[31m"
Yellow="\033[33m"
Blue="\033[36m"
Font="\033[0m"
GreenBG="\033[42;37m"
RedBG="\033[41;37m"
OK="${Green}[OK]${Font}"
ERROR="${Red}[ERROR]${Font}"

# 变量
shell_version="1.0.0"
Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Green_font_prefix}[注意]${Font_color_suffix}"
realm_conf_path="/opt/realm/config.json"
raw_conf_path="/opt/realm/rawconf"

# check root
[[ $EUID -ne 0 ]] && echo -e "${Red}错误：${Font} 必须使用root用户运行此脚本！\n" && exit 1

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
    echo -e "${red}未检测到系统版本${plain}\n" && exit 1
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

confirm() {
    if [[ $# > 1 ]]; then
        echo && read -p "$1 [默认$2]: " temp
        if [[ x"${temp}" == x"" ]]; then
            temp=$2
        fi
    else
        read -p "$1 [y/n]: " temp
    fi
    if [[ x"${temp}" == x"y" || x"${temp}" == x"Y" ]]; then
        return 0
    else
        return 1
    fi
}

print_ok() {
  echo -e "${OK} ${Blue} $1 ${Font}"
}

print_error() {
  echo -e "${ERROR} ${RedBG} $1 ${Font}"
}

judge() {
  if [[ 0 -eq $? ]]; then
    print_ok "$1 完成"
    sleep 1
  else
    print_error "$1 失败"
    exit 1
  fi
}

before_show_menu() {
    echo && echo -n -e "${Yellow}按回车返回主菜单: ${Font}" && read temp
    start_menu
}

#检测是否安装Realm
# 0: running, 1: not running, 2: not installed
check_status() {
    if [[ ! -f /etc/systemd/system/realm.service ]]; then
        return 2
    fi
    temp=$(systemctl status realm | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
    if [[ x"${temp}" == x"running" ]]; then
        return 0
    else
        return 1
    fi
}

check_enabled() {
    temp=$(systemctl is-enabled realm)
    if [[ x"${temp}" == x"enabled" ]]; then
        return 0
    else
        return 1;
    fi
}

check_uninstall() {
    check_status
    if [[ $? != 2 ]]; then
        echo ""
        echo -e "${Red}Realm已安装，请不要重复安装${Font}"
        before_show_menu
        return 1
    else
        return 0
    fi
}

check_install() {
    check_status
    if [[ $? == 2 ]]; then
        echo ""
        echo -e "${Red}请先安装Realm${Font}"
        before_show_menu
        return 1
    else
        return 0
    fi
}

show_status() {
    check_status
    case $? in
        0)
            echo -e "Realm状态: ${Green}已运行${Font}"
            show_enable_status
            ;;
        1)
            echo -e "Realm状态: ${Yellow}未运行${Font}"
            show_enable_status
            ;;
        2)
            echo -e "Realm状态: ${Red}未安装${Font}"
    esac
}

show_enable_status() {
    check_enabled
    if [[ $? == 0 ]]; then
        echo -e "是否开机自启: ${Green}是${Font}"
    else
        echo -e "是否开机自启: ${Red}否${Font}"
    fi
}

#安装Realm
Install_Realm(){
  check_uninstall
  if [[ x"${release}" == x"centos" ]]; then
    yum install python3 -y
  elif [[ x"${release}" == x"ubuntu" ]]; then
    apt-get install python3 -y
  elif [[ x"${release}" == x"debian" ]]; then
    apt-get install python3 -y
  fi
  [ -e /opt/realm/ ] || mkdir -p /opt/realm/
  echo -e "######################################################"
  echo -e "#    请选择下载点:  1.国外   2.国内                  #"
  echo -e "######################################################"
  read -p "请选择(默认国外): " download
  [[ -z ${download} ]] && download="1"
  if [[ ${download} == [2] ]]; then
      wget -N --no-check-certificate -O /opt/realm/realm https://ghproxy.com/https://github.com/zhboner/realm/releases/download/v1.4/realm && chmod +x /opt/realm/realm
  elif [[ ${download} == [1] ]]; then
      URL="$(wget -qO- https://api.github.com/repos/zhboner/realm/releases/latest | grep -E "browser_download_url.*realm" | cut -f4 -d\")"    
      wget -N --no-check-certificate -O /opt/realm/realm ${URL} && chmod +x /opt/realm/realm
  else
      print_error "输入错误，请重新输入！"
      before_show_menu
  fi
echo '
{
    "listening_addresses": ["0.0.0.0"],
    "listening_ports": [],
    "remote_addresses": [],
    "remote_ports": []
} ' > /opt/realm/config.json
echo '
[Unit]
Description=Realm
After=network-online.target
Wants=network-online.target systemd-networkd-wait-online.service

[Service]
LimitCORE=infinity
LimitNOFILE=512000
LimitNPROC=512000
Type=simple
User=root
Restart=always
RestartSec=5s
DynamicUser=yes
WorkingDirectory=/opt/realm
ExecStart=/opt/realm/realm -c /opt/realm/config.json

[Install]
WantedBy=multi-user.target' > /etc/systemd/system/realm.service
  systemctl enable realm --now
    if test -a /opt/realm/realm -a /etc/systemd/system/realm.service -a /opt/realm/config.json;then
        print_ok "Realm安装完成"
    else
        print_error "Realm安装失败"
        rm -rf /opt/realm/realm /opt/realm/config.json /etc/systemd/system/realm.service
    fi
  sleep 3s
  start_menu
}

#更新realm
Update_Realm(){
    confirm "本功能会强制重装当前最新版，数据不会丢失，是否继续?" "n"
    if [[ $? != 0 ]]; then
        echo -e "${red}已取消${plain}"
        before_show_menu
        return 0
    fi
    [ -e /opt/realm/ ] || mkdir -p /opt/realm/
    echo -e "######################################################"
    echo -e "#    请选择下载点:  1.国外   2.国内                  #"
    echo -e "######################################################"
    read -p "请选择(默认国外): " download
    [[ -z ${download} ]] && download="1"
    if [[ ${download} == [2] ]]; then
        wget -N --no-check-certificate -O /opt/realm/realm https://ghproxy.com/https://github.com/zhboner/realm/releases/download/v1.4/realm && chmod +x /opt/realm/realm
    elif [[ ${download} == [1] ]]; then
        URL="$(wget -qO- https://api.github.com/repos/zhboner/realm/releases/latest | grep -E "browser_download_url.*realm" | cut -f4 -d\")"    
        wget -N --no-check-certificate -O /opt/realm/realm ${URL} && chmod +x /opt/realm/realm
    else
      print_error "输入错误，请重新输入！"
      before_show_menu
    fi
    systemctl restart realm
    check_status
    if [[ $? == 0 ]]; then
        print_ok "更新完成，已自动重启Realm"
        exit 0
    fi
}

#卸载Realm
Uninstall_Realm(){
    check_install
    confirm "确定要卸载Realm吗?" "n"
    if [[ $? != 0 ]]; then
        start_menu
        return 0
    fi
    systemctl stop realm
    systemctl disable realm
    rm -rf /opt/realm/realm /opt/realm/config.json /etc/systemd/system/realm.service
    systemctl daemon-reload
    systemctl reset-failed
    print_ok "Realm卸载成功"
    before_show_menu
}
#启动Realm
Start_Realm(){
    check_install
    check_status
    if [[ $? == 0 ]]; then
        echo ""
        print_ok "Realm已运行，无需再次启动，如需重启请选择重启"
    else
        systemctl start realm
        sleep 2
        check_status
        if [[ $? == 0 ]]; then
            print_ok "${Green}Realm启动成功${Font}"
        else
            print_error "Realm启动失败，可能是因为启动时间超过了两秒，请稍后查看日志信息"
        fi
    fi
    before_show_menu
}

#停止Realm
Stop_Realm(){
    check_install
    check_status
    if [[ $? == 1 ]]; then
        echo ""
        print_ok "Realm已停止，无需再次停止"
    else
        systemctl stop realm
        sleep 2
        check_status
        if [[ $? == 1 ]]; then
            print_ok "Realm停止成功"
        else
            print_error "Realm停止失败，可能是因为停止时间超过了两秒，请稍后查看日志信息"
        fi
    fi
    before_show_menu
}

#重启Realm
Restart_Realm(){
    check_install
    systemctl restart realm
    sleep 2
    check_status
    if [[ $? == 0 ]]; then
        print_ok "Realm重启成功"
    else
        print_error "Realm重启失败，可能是因为启动时间超过了两秒，请稍后查看日志信息"
    fi
    before_show_menu
}

#查看Realm
Status_Realm(){
    check_install
    systemctl status realm -l
    before_show_menu
}

#设置Realm自启
Enable_Realm(){
    check_install
    systemctl enable realm
    if [[ $? == 0 ]]; then
        print_ok "Realm设置开机自启成功"
    else
        print_error "Realm设置开机自启失败"
    fi
    before_show_menu
}

#取消Realm自启
Disable_Realm(){
    check_install
    systemctl disable realm
    if [[ $? == 0 ]]; then
        print_ok "Realm取消开机自启成功"
    else
        print_error "Realm取消开机自启失败"
    fi
    before_show_menu
}

#添加设置
Set_Config(){
read -e -p " 请输入本地端口[1-65535] (支持端口段如100-102,数量要和目标端口相同):" listening_ports
if [[ -z "${listening_ports}" ]]; then
    echo -e "${Yellow}已取消${Font}"
    before_show_menu
fi
if [[ ! "${listening_ports}" =~ ^[0-9]+$ ]]; then   
    echo -e "${Red}请输入正确的数字格式${plain}"
    before_show_menu
fi
listening_ports_count=$(cat /opt/realm/rawconf |cut -d\/ -f1 |grep "${listening_ports}" |wc -l)
if [[ "${listening_ports_count}" -eq 1 ]]; then   
    echo -e "${Red}您输入的端口已存在，请换一个端口${plain}"
    before_show_menu
fi
read -e -p " 请输入转发的目标地址/IP :" remote_addresses
if [[ -z "${remote_addresses}" ]]; then
    echo -e "${Yellow}已取消${Font}"
    before_show_menu
fi
if [[ $remote_addresses =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]];then
    c=`echo $remote_addresses |cut -d. -f1`
    d=`echo $remote_addresses |cut -d. -f2`
    e=`echo $remote_addresses |cut -d. -f3`
    f=`echo $remote_addresses |cut -d. -f4`
    if [ $c -gt 255 -o $d -gt 255 -o $e -gt 255 -o $f -gt 255 ];then
        echo -e "${Red}请输入正确格式的IP${plain}"
        before_show_menu
    fi
fi

read -e -p " 请输入目标端口[1-65535] (支持端口段如100-102，数量要和监听端口相同):" remote_ports
if [[ -z "${remote_ports}" ]]; then
    echo -e "${Yellow}已取消${Font}"
    before_show_menu
fi
if [[ ! "${remote_ports}" =~ ^[0-9]+$ ]]; then   
    echo -e "${Red}请输入正确的数字格式${plain}"
    before_show_menu
fi 
    echo && echo -e "—————————————————————————————————————————————
    请检查Realm转发规则配置是否有误 !\n
    本 地 监 听 端 口    : ${Green}${listening_ports}${Font}
    目 标 的 地址/IP  : ${Green}${remote_addresses}${Font}
    目 标 的 端 口    : ${Green}${remote_ports}${Font}

—————————————————————————————————————————————\n"
    read -e -p "按任意键继续，如有配置错误请使用 Ctrl+C 退出。" temp
    if [ `grep -c "listening_ports" /opt/realm/config.json` -eq '0' ]; then
        python3 -c "import json;j = (json.load(open(\"/opt/realm/config.json\",'r')));a = {'listening_ports':['$listening_ports']};j.update(a);print (j['listening_ports']);json.dump(j,open(\"/opt/realm/config.json\",'w'))" && echo -e "${Info} 配置更新成功"
    else
        python3 -c "import json;j = (json.load(open(\"/opt/realm/config.json\",'r')));j['listening_ports'].append( \"$listening_ports\");print (j['listening_ports']);json.dump(j,open(\"/opt/realm/config.json\",'w'))" && echo -e "${Info} 配置更新成功"
    fi
    
    if [ `grep -c "remote_addresses" /opt/realm/config.json` -eq '0' ]; then
        python3 -c "import json;j = (json.load(open(\"/opt/realm/config.json\",'r')));a = {'remote_addresses':['$remote_addresses']};j.update(a);print (j['remote_addresses']);json.dump(j,open(\"/opt/realm/config.json\",'w'))" && echo -e "${Info} 配置更新成功"
    else
        python3 -c "import json;j = (json.load(open(\"/opt/realm/config.json\",'r')));j['remote_addresses'].append( \"$remote_addresses\");print (j['remote_addresses']);json.dump(j,open(\"/opt/realm/config.json\",'w'))" && echo -e "${Info} 配置更新成功"
    fi

    if [ `grep -c "remote_ports" /opt/realm/config.json` -eq '0' ]; then
        python3 -c "import json;j = (json.load(open(\"/opt/realm/config.json\",'r')));a = {'remote_ports':['$remote_ports']};j.update(a);print (j['remote_ports']);json.dump(j,open(\"/opt/realm/config.json\",'w'))" && echo -e "${Info} 配置更新成功"
    else
        python3 -c "import json;j = (json.load(open(\"/opt/realm/config.json\",'r')));j['remote_ports'].append( \"$remote_ports\");print (j['remote_ports']);json.dump(j,open(\"/opt/realm/config.json\",'w'))" && echo -e "${Info} 配置更新成功"
    fi
    echo $listening_ports"/"$remote_addresses"#"$remote_ports >> $raw_conf_path
}

localport_conf(){
    count_line=$(awk 'END{print NR}' $raw_conf_path)
    for((i=1;i<=$count_line;i++))
    do
        trans_conf=$(sed -n "${i}p" $raw_conf_path)
        eachconf_retrieve
        if [ `grep -c "listening_ports" /opt/realm/config.json` -eq '0' ]; then
            python3 -c "import json;j = (json.load(open(\"/opt/realm/config.json\",'r')));a = {'listening_ports':['$listening_ports']};j.update(a);print (j['listening_ports']);json.dump(j,open(\"/opt/realm/config.json\",'w'))" && echo -e "${Info} 配置更新成功"
        else
            python3 -c "import json;j = (json.load(open(\"/opt/realm/config.json\",'r')));j['listening_ports'].append( \"$listening_ports\");print (j['listening_ports']);json.dump(j,open(\"/opt/realm/config.json\",'w'))" && echo -e "${Info} 配置更新成功"
        fi
    done
}

addresses_conf(){
    count_line=$(awk 'END{print NR}' $raw_conf_path)
    for((i=1;i<=$count_line;i++))
    do
        trans_conf=$(sed -n "${i}p" $raw_conf_path)
        eachconf_retrieve
        if [ `grep -c "remote_addresses" /opt/realm/config.json` -eq '0' ]; then
            python3 -c "import json;j = (json.load(open(\"/opt/realm/config.json\",'r')));a = {'remote_addresses':['$remote_addresses']};j.update(a);print (j['remote_addresses']);json.dump(j,open(\"/opt/realm/config.json\",'w'))" && echo -e "${Info} 配置更新成功"
        else
            python3 -c "import json;j = (json.load(open(\"/opt/realm/config.json\",'r')));j['remote_addresses'].append( \"$remote_addresses\");print (j['remote_addresses']);json.dump(j,open(\"/opt/realm/config.json\",'w'))" && echo -e "${Info} 配置更新成功"
        fi
    done
}

remoteport_conf(){
    count_line=$(awk 'END{print NR}' $raw_conf_path)
    for((i=1;i<=$count_line;i++))
    do
        trans_conf=$(sed -n "${i}p" $raw_conf_path)
        eachconf_retrieve
        if [ `grep -c "remote_ports" /opt/realm/config.json` -eq '0' ]; then
            python3 -c "import json;j = (json.load(open(\"/opt/realm/config.json\",'r')));a = {'remote_ports':['$remote_ports']};j.update(a);print (j['remote_ports']);json.dump(j,open(\"/opt/realm/config.json\",'w'))" && echo -e "${Info} 配置更新成功"
        else
            python3 -c "import json;j = (json.load(open(\"/opt/realm/config.json\",'r')));j['remote_ports'].append( \"$remote_ports\");print (j['remote_ports']);json.dump(j,open(\"/opt/realm/config.json\",'w'))" && echo -e "${Info} 配置更新成功"
        fi    
    done
}

#赋值
eachconf_retrieve()
{
    a=${trans_conf}
    b=${a#*/}
    listening_ports=${trans_conf%/*}
    remote_addresses=${b%#*}
    remote_ports=${trans_conf#*#}
}

#添加Realm转发规则
Add_Realm(){
Set_Config
echo -e "--------${Green_font_prefix} 规则添加成功! ${Font_color_suffix}--------"
read -p "输入任意键按回车返回主菜单"
start_menu
}

#查看规则
Check_Realm(){
    echo -e "                      Realm 配置                        "
    echo -e "--------------------------------------------------------"
    echo -e "序号|本地端口\t|目标地址:目标端口"
    echo -e "--------------------------------------------------------"

    count_line=$(awk 'END{print NR}' $raw_conf_path)
    for((i=1;i<=$count_line;i++))
    do
        trans_conf=$(sed -n "${i}p" $raw_conf_path)
        eachconf_retrieve
        echo -e " $i  |  $listening_ports\t|$remote_addresses:$remote_ports"
        echo -e "--------------------------------------------------------"
    done
read -p "输入任意键按回车返回主菜单"
start_menu
}

#删除Realm转发规则
Delete_Realm(){
    echo -e "                      Realm 配置                        "
    echo -e "--------------------------------------------------------"
    echo -e "序号|本地端口\t|目标地址:目标端口"
    echo -e "--------------------------------------------------------"

    count_line=$(awk 'END{print NR}' $raw_conf_path)
    for((i=1;i<=$count_line;i++))
    do
        trans_conf=$(sed -n "${i}p" $raw_conf_path)
        eachconf_retrieve
        echo -e " $i  |$listening_ports\t|$remote_addresses:$remote_ports"
        echo -e "--------------------------------------------------------"
    done
read -p "请输入你要删除的配置序号：" numdelete
trans_conf=$(sed -n "${numdelete}p" $raw_conf_path)
eachconf_retrieve
python3 -c "import json;j = (json.load(open(\"/opt/realm/config.json\",'r')));j['listening_ports'].remove( \"$listening_ports\");print (j['listening_ports']);json.dump(j,open(\"/opt/realm/config.json\",'w'))" && echo -e "${Info} 配置更新成功"
python3 -c "import json;j = (json.load(open(\"/opt/realm/config.json\",'r')));j['remote_addresses'].remove( \"$remote_addresses\");print (j['remote_addresses']);json.dump(j,open(\"/opt/realm/config.json\",'w'))" && echo -e "${Info} 配置更新成功"
python3 -c "import json;j = (json.load(open(\"/opt/realm/config.json\",'r')));j['remote_ports'].remove( \"$remote_ports\");print (j['remote_ports']);json.dump(j,open(\"/opt/realm/config.json\",'w'))" && echo -e "${Info} 配置更新成功"
sed -i "${numdelete}d" $raw_conf_path
systemctl restart realm
echo -e "------------------${Red_font_prefix}配置已删除,服务已重启${Font_color_suffix}-----------------"
sleep 2s
clear
echo -e "----------------------${Green_font_prefix}当前配置如下${Font_color_suffix}----------------------"
echo -e "--------------------------------------------------------"
Check_Realm
read -p "输入任意键按回车返回主菜单"
start_menu
}

#修改realm规则
Edit_Realm(){
    echo -e "                      Realm 配置                        "
    echo -e "--------------------------------------------------------"
    echo -e "序号|本地端口\t|目标地址:目标端口"
    echo -e "--------------------------------------------------------"

    count_line=$(awk 'END{print NR}' $raw_conf_path)
    for((i=1;i<=$count_line;i++))
    do
        trans_conf=$(sed -n "${i}p" $raw_conf_path)
        eachconf_retrieve
        echo -e " $i  |$listening_ports\t|$remote_addresses:$remote_ports"
        echo -e "--------------------------------------------------------"
    done
read -p "请输入你要修改的配置序号：" numedit
Set_Config
trans_conf=$(sed -n "${numedit}p" $raw_conf_path)
eachconf_retrieve
python3 -c "import json;j = (json.load(open(\"/opt/realm/config.json\",'r')));j['listening_ports'].remove( \"$listening_ports\");print (j['listening_ports']);json.dump(j,open(\"/opt/realm/config.json\",'w'))" && echo -e "${Info} 配置更新成功"
python3 -c "import json;j = (json.load(open(\"/opt/realm/config.json\",'r')));j['remote_addresses'].remove( \"$remote_addresses\");print (j['remote_addresses']);json.dump(j,open(\"/opt/realm/config.json\",'w'))" && echo -e "${Info} 配置更新成功"
python3 -c "import json;j = (json.load(open(\"/opt/realm/config.json\",'r')));j['remote_ports'].remove( \"$remote_ports\");print (j['remote_ports']);json.dump(j,open(\"/opt/realm/config.json\",'w'))" && echo -e "${Info} 配置更新成功"
sed -i "${numedit}d" $raw_conf_path
systemctl restart realm
echo -e "------------------${Red_font_prefix}配置已修改,服务已重启${Font_color_suffix}-----------------"
sleep 2s
clear
echo -e "----------------------${Green_font_prefix}当前配置如下${Font_color_suffix}----------------------"
echo -e "--------------------------------------------------------"
Check_Realm
read -p "输入任意键按回车返回主菜单"
start_menu
}

#更新脚本
Update_Shell(){
    echo -e "当前版本为 [ ${shell_version} ]，开始检测最新版本..."
    ol_version=$(curl -L -s "https://ghproxy.com/https://github.com/myxuchangbin/shellscript/raw/master/realm.sh" | grep "shell_version=" | head -1 | awk -F '=|"' '{print $3}')
    if [[ "$shell_version" != "$(echo -e "$shell_version\n$ol_version" | sort -rV | head -1)" ]]; then
        print_ok "存在新版本，是否更新 [Y/N]?"
        read -rp "(默认: y):" update_confirm
        [[ -z "${yn}" ]] && yn="y"
        case $update_confirm in
        [yY][eE][sS] | [yY])
          wget -N --no-check-certificate https://ghproxy.com/https://github.com/myxuchangbin/shellscript/raw/master/realm.sh && chmod +x realm.sh
          print_ok "更新完成"
          print_ok "您可以通过 bash $0 执行本程序"
          exit 0
        ;;
        *) ;;
        esac
    else
        print_ok "当前版本为最新版本"
        print_ok "您可以通过 bash $0 执行本程序"
    fi
}

#备份配置
Backup(){
    if test -a /opt/realm/rawconf;then
    cp /opt/realm/rawconf /opt/realm/rawconf.back
    echo -e " ${Green_font_prefix}备份完成！${Font_color_suffix}"
    sleep 3s
    start_menu
    else
    echo -e " ${Red_font_prefix}未找到配置文件，备份失败${Font_color_suffix}"
    sleep 3s
    start_menu
    fi
}

#恢复配置
Recovey(){
    if test -a /opt/realm/rawconf.back;then
    rm -f /opt/realm/rawconf
    cp /opt/realm/rawconf.back /opt/realm/rawconf
    echo -e " ${Green_font_prefix}恢复完成！${Font_color_suffix}"
    sleep 3s
    start_menu
    else
    echo -e " ${Red_font_prefix}未找到备份文件，恢复失败${Font_color_suffix}"
    sleep 3s
    start_menu
    fi
}

#备份/恢复配置
Backup_Recovey(){
clear
echo -e "
 ${Green_font_prefix}1.${Font_color_suffix} 备份配置
 ${Green_font_prefix}2.${Font_color_suffix} 恢复配置
 ${Green_font_prefix}3.${Font_color_suffix} 删除备份"
echo
 read -p " 请输入数字后[1-2] 按回车键:" num2
 case "$num2" in
    1)
     Backup
    ;;
    2)
     Recovey 
    ;;
    3)
     if test -a /opt/realm/rawconf.back;then
       rm -f /opt/realm/rawconf.back
       echo -e " ${Green_font_prefix}删除成功！${Font_color_suffix}"
       sleep 3s
       start_menu
     else
       echo -e " ${Red_font_prefix}未找到备份文件，删除失败${Font_color_suffix}"   
       sleep 3s
       start_menu
     fi
    ;;
    *)
     esac
     echo -e "${Error}:请输入正确数字 [1-2] 按回车键"
     sleep 3s
     Backup_Recovey
}

#初始化Realm配置
Init_Realm(){
    confirm "本功能强制初始化Realm，数据会丢失，是否继续?" "n"
    if [[ $? != 0 ]]; then
        echo -e "${red}已取消${plain}"
        before_show_menu
        return 0
    fi
    rm -rf /opt/realm/rawconf
    rm -rf /opt/realm/config.json
echo '
{
    "listening_addresses": ["0.0.0.0"],
    "listening_ports": [],
    "remote_addresses": [],
    "remote_ports": []
} ' > /opt/realm/config.json
    read -p "初始化成功,输入任意键按回车返回主菜单"
    start_menu
}

#重载Realm配置
Reload_Realm(){
  rm -rf /opt/realm/config.json
echo '
{
    "listening_addresses": ["0.0.0.0"],
    "listening_ports": [],
    "remote_addresses": [],
    "remote_ports": []
} ' > /opt/realm/config.json
  localport_conf
  addresses_conf
  remoteport_conf
  systemctl restart realm
  read -p "重载配置成功,输入任意键按回车返回主菜单"
  start_menu
}

#定时重启任务
Time_Task(){
  clear
  echo -e "#############################################################"
  echo -e "#                       Realm定时重启任务                   #"
  echo -e "#############################################################" 
  echo -e   
  crontab -l > /tmp/cronconf
  echo -e "${Green_font_prefix}1.配置Realm定时重启任务${Font_color_suffix}"
  echo -e "${Red_font_prefix}2.删除Realm定时重启任务${Font_color_suffix}"
  read -p "请选择: " numtype
  if [ "$numtype" == "1" ]; then  
      if grep -wq "realm" /tmp/cronconf;then
          sed -i "/realm/d" /tmp/cronconf
      fi
      echo -e "请选择定时重启任务类型:"
      echo -e "1.分钟 2.小时 3.天" 
      read -p "请输入类型: " type_num
      case "$type_num" in
        1)
      echo -e "请设置每多少分钟重启Realm任务"   
      read -p "请设置分钟数: " type_m
      echo "*/$type_m * * * *  /usr/bin/systemctl restart realm" >> /tmp/cronconf
        ;;
        2)
      echo -e "请设置每多少小时重启Realm任务"   
      read -p "请设置小时数: " type_h
      echo "0 */$type_h * * *  /usr/bin/systemctl restart realm" >> /tmp/cronconf
        ;;
        3)
      echo -e "请设置每多少天重启Realm任务"    
      read -p "请设置天数: " type_d
      echo "0 0 */$type_d * *  /usr/bin/systemctl restart realm" >> /tmp/cronconf
        ;;
        *)
        clear
        echo -e "${Error}:请输入正确数字 [1-3] 按回车键"
        sleep 3s
        Time_Task
        ;;
      esac
      crontab /tmp/cronconf
      echo -e "${Green_font_prefix}设置成功!${Font_color_suffix}"   
      read -p "输入任意键按回车返回主菜单"
      start_menu   
  elif [ "$numtype" == "2" ]; then
      if grep -wq "realm" /tmp/cronconf;then
          sed -i "/realm/d" /tmp/cronconf
      fi
      crontab /tmp/cronconf
      echo -e "${Green_font_prefix}定时重启任务删除完成！${Font_color_suffix}"
      read -p "输入任意键按回车返回主菜单"
      start_menu    
  else
      echo "输入错误，请重新输入！"
      sleep 3s
      Time_Task
  fi
  rm -f /tmp/cronconf  
}

#主菜单
start_menu(){
clear
echo -e ""
echo -e "\tRealm 安装管理脚本  ${Red}[${shell_version}]${Font}"
echo -e ""
echo -e "
—————————————— 安装向导 ——————————————
 ${Green_font_prefix}0.${Font_color_suffix} 更新脚本
 ${Green_font_prefix}1.${Font_color_suffix} 安装 Realm
 ${Green_font_prefix}2.${Font_color_suffix} 更新 Realm
 ${Green_font_prefix}3.${Font_color_suffix} 卸载 Realm
—————————————— 服务管理 ——————————————
${Green_font_prefix}11.${Font_color_suffix} 启动 Realm
${Green_font_prefix}12.${Font_color_suffix} 停止 Realm
${Green_font_prefix}13.${Font_color_suffix} 重启 Realm
${Green_font_prefix}14.${Font_color_suffix} 查看 Realm 状态 
${Green_font_prefix}15.${Font_color_suffix} 设置 Realm 开机自启
${Green_font_prefix}16.${Font_color_suffix} 取消 Realm 开机自启
—————————————— 规则管理 ——————————————
${Green_font_prefix}21.${Font_color_suffix} 添加一条 Realm 规则
${Green_font_prefix}22.${Font_color_suffix} 删除一条 Realm 规则
${Green_font_prefix}23.${Font_color_suffix} 修改一条 Realm 规则
${Green_font_prefix}24.${Font_color_suffix} 查看所有 Realm 规则
${Green_font_prefix}25.${Font_color_suffix} 重新加载 Realm 规则(手动修改/opt/realm/rawconf后进行加载)
${Green_font_prefix}26.${Font_color_suffix} 初始化   Realm 规则(会清空现有规则)
—————————————— 其他选项 ——————————————
${Green_font_prefix}31.${Font_color_suffix} 备份/恢复配置
${Green_font_prefix}32.${Font_color_suffix} 添加定时重启任务(可以缓解长时间运行内存泄漏的问题)
${Green_font_prefix}40.${Font_color_suffix} 退出脚本
"
 show_status
echo &&read -p " 请输入数字后，按回车键:" num
case "$num" in
    1)
    Install_Realm
    ;;
    2)
    Update_Realm
    ;;
    3)
    Uninstall_Realm
    ;;
    11)
    Start_Realm
    ;;
    12)
    Stop_Realm
    ;;  
    13)
    Restart_Realm
    ;;
    14)
    Status_Realm
    ;;
    15)
    Enable_Realm
    ;;
    16)
    Disable_Realm
    ;;      
    21)
    Add_Realm
    ;;
    22)
    Delete_Realm
    ;;
    23)
    Edit_Realm
    ;;
    24)
    Check_Realm
    ;;
    25)
    Reload_Realm
    ;;
    26)
    Init_Realm
    ;;
    31)
    Backup_Recovey
    ;;
    32)
    Time_Task
    ;;
    40)
    exit 0
    ;;
    0)
    Update_Shell
    ;;
    *)
    print_error "请输入正确的数字"
    ;;
esac
}
start_menu
