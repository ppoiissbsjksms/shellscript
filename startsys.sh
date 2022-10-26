#!/usr/bin/env bash
#Remarks: 适用于centos7 debian ubuntu的新系统优化脚本
#Update: 2022-10-26
#Warning: 脚本用于个人测试，请谨慎用于生产环境

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

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

GITHUB_RAW_URL="raw.githubusercontent.com"
GITHUB_URL="github.com"
import_key=0
if [ -n "$*" ]; then
    if echo "$*" | grep -qwi "cn"; then
        GITHUB_RAW_URL="raw.fastgit.org"
        GITHUB_URL="hub.fastgit.org"
    fi
    if echo "$*" | grep -qwi "k"; then
        import_key=1
    fi
fi
#安装一些常用软件包
install(){
        echo -e "${yellow}安装一些常用软件包${plain}"
        if [[ x"${release}" == x"centos" ]]; then
            if [ ${os_version} -eq 7 ]; then
                yum clean all
                yum makecache
                yum -y install epel-release
                yum -y install vim wget curl zip unzip bash-completion git tree mlocate lrzsz crontabs libsodium tar lsof nmap nload screen nano python-devel python-pip python3-devel python3-pip socat nc ioping mtr bind-utils yum-utils ntpdate gcc gcc-c++ make iftop traceroute net-tools fping vnstat pciutils iperf3 iotop htop sysstat tcpdump bc cmake openssl openssl-devel gnutls ca-certificates systemd sudo
                update-ca-trust force-enable
            elif [ ${os_version} -eq 8 ]; then
                dnf -y install epel-release
                dnf -y install vim wget curl zip unzip bash-completion git tree mlocate lrzsz crontabs libsodium tar lsof nmap nload screen nano python2-devel python2-pip python3-devel python3-pip socat nc ioping mtr bind-utils yum-utils gcc gcc-c++ make iftop traceroute net-tools fping vnstat pciutils iperf3 iotop htop sysstat tcpdump bc cmake openssl openssl-devel gnutls ca-certificates systemd sudo
            fi
        elif [[ x"${release}" == x"ubuntu" ]]; then
            apt update -y
            apt install -y vim wget curl lrzsz tar lsof nmap dnsutils nload iperf3 screen cron openssl libsodium-dev libgnutls30 ca-certificates systemd python-dev python-pip python3-dev python3-pip
        elif [[ x"${release}" == x"debian" ]]; then
            apt update -y
            apt install -y vim wget curl lrzsz tar lsof nmap dnsutils nload iperf3 screen cron openssl libsodium-dev libgnutls30 ca-certificates systemd python-dev python-pip python3-dev python3-pip
        fi
        echo -e "${green}完成${plain}"
}

#优化安全及一些个性化设置
set_securite(){
    echo -e "${yellow}检查SeLinux并关闭${plain}"
        if grep -q "^UseDNS" /etc/ssh/sshd_config;then
            sed -i '/^UseDNS/s/yes/no/' /etc/ssh/sshd_config
        else
           sed -i '$a UseDNS no' /etc/ssh/sshd_config
        fi
        if grep -q "^GSSAPIAuthentication" /etc/ssh/sshd_config;then
            sed -i '/^GSSAPIAuthentication/s/yes/no/' /etc/ssh/sshd_config
        else
           sed -i '$a GSSAPIAuthentication no' /etc/ssh/sshd_config
        fi
        if grep -q "^PermitEmptyPasswords" /etc/ssh/sshd_config;then
            sed -i '/^PermitEmptyPasswords/s/yes/no/' /etc/ssh/sshd_config
        else
           sed -i '$a PermitEmptyPasswords no' /etc/ssh/sshd_config
        fi
        sed -i '/SELINUX/s/enforcing/disabled/' /etc/selinux/config && setenforce 0
    echo -e "${green}完成${plain}"
    #安全提示：脚本输入k参数，会默认添加作者个人公钥到服务器，请谨慎运行！！！
    if [[ "${import_key}" == "1" ]]; then
        echo -e "${yellow}检查并添加作者SSH公钥${plain}"
            [ -e /root/.ssh ] || mkdir -p /root/.ssh
            [ -e /root/.ssh/authorized_keys ] || touch /root/.ssh/authorized_keys
            if [ `grep -c "#pkey20220322" /root/.ssh/authorized_keys` -eq 0 ];then
                wget -O /tmp/id_rsa_1024.pub https://${GITHUB_RAW_URL}/myxuchangbin/shellscript/master/id_rsa_1024.pub
                if echo "03533eeb543c816baab80ef55330eca9  /tmp/id_rsa_1024.pub" | md5sum -c; then
                    cat /tmp/id_rsa_1024.pub >> /root/.ssh/authorized_keys
                    echo -e "\n#pkey20220322" >> /root/.ssh/authorized_keys
                fi
                rm -f /tmp/id_rsa_1024.pub
            fi
        echo -e "${green}完成${plain}"
    fi
    echo -e "${yellow}检查系统时区${plain}"
        if [[ x"${release}" == x"centos" ]]; then
            if [ ${os_version} -eq 7 ]; then
                if [ `timedatectl | grep "Time zone" | grep -c "Asia/Shanghai"` -eq 0 ];then
                    timedatectl set-timezone Asia/Shanghai
                    sed -i 's%SYNC_HWCLOCK=no%SYNC_HWCLOCK=yes%' /etc/sysconfig/ntpdate
                fi
                ntpdate ntp.aliyun.com
                hwclock -w
            elif [ ${os_version} -eq 8 ]; then
                if [ `timedatectl | grep "Time zone" | grep -c "Asia/Shanghai"` -eq 0 ];then
                    timedatectl set-timezone Asia/Shanghai
                    echo "server ntp.aliyun.com iburst" >>/etc/chrony.conf
                    echo "server ntp.7io.com iburst" >>/etc/chrony.conf
                    systemctl restart chronyd.service
                    chronyc sources -v 
                fi
            fi
        elif [[ x"${release}" == x"ubuntu" ]]; then
            if [ `timedatectl | grep "Time zone" | grep -c "Asia/Shanghai"` -eq 0 ];then
                timedatectl set-timezone Asia/Shanghai
            fi 
        elif [[ x"${release}" == x"debian" ]]; then
            if [ `timedatectl | grep "Time zone" | grep -c "Asia/Shanghai"` -eq 0 ];then
                timedatectl set-timezone Asia/Shanghai
            fi 
        fi
    echo -e "${green}完成${plain}"
    echo -e "${yellow}检查历史命令是否记录时间点${plain}"
        if [ `grep -c "#history20210402" /etc/profile` -eq 0 ];then
            echo "export HISTTIMEFORMAT=\"%F %T \`whoami\` \" #history20210402" >> /etc/profile
        fi
    echo -e "${green}完成${plain}"
    echo -e "${yellow}禁止键盘重启系统命令${plain}"
        rm -rf /usr/lib/systemd/system/ctrl-alt-del.target
    echo -e "${green}完成${plain}"
    echo -e "${yellow}检查系统字符集${plain}"
        if [[ x"${release}" == x"centos" ]]; then
            localedef -c -f UTF-8 -i zh_CN zh_CN.UTF-8
            export LC_ALL=zh_CN.UTF-8
            if grep -q "^LANG" /etc/locale.conf;then
                sed -i '/^LANG=/s/.*/LANG=zh_CN.UTF-8/' /etc/locale.conf
            else
               sed -i '$a LANG=zh_CN.UTF-8' /etc/locale.conf
            fi
        elif [[ x"${release}" == x"ubuntu" ]]; then
            echo -e "${yellow}暂无调整${plain}"
        elif [[ x"${release}" == x"debian" ]]; then
            echo -e "${yellow}暂无调整${plain}"
        fi
    echo -e "${green}完成${plain}"
    echo -e "${yellow}检查定时释放内存${plain}"
        crontab -l > /tmp/drop_cachescronconf
        if grep -wq "drop_caches" /tmp/drop_cachescronconf;then
            sed -i "/drop_caches/d" /tmp/drop_cachescronconf
        fi
        echo "0 6 * * * sync; echo 3 > /proc/sys/vm/drop_caches" >> /tmp/drop_cachescronconf
        crontab /tmp/drop_cachescronconf
        rm -f /tmp/drop_cachescronconf
    echo -e "${green}完成${plain}"
}

#优化系统最大句柄数限制
set_file(){
    echo -e "${yellow}优化系统最大句柄数限制${plain}"
    if [ `grep -c "#limits20210402" /etc/security/limits.conf` -eq 0 ];then
        echo "root soft nofile 512000" >> /etc/security/limits.conf
        echo "root hard nofile 512000" >> /etc/security/limits.conf
        echo "* soft nofile 512000" >> /etc/security/limits.conf
        echo "* hard nofile 512000" >> /etc/security/limits.conf
        echo "* soft nproc  512000" >> /etc/security/limits.conf
        echo "* hard nproc  512000" >> /etc/security/limits.conf
        echo -e "\n#limits20210402" >> /etc/security/limits.conf
        if [[ x"${release}" == x"centos" ]]; then
            if [ ${os_version} -eq 7 ]; then
                sed -i 's/4096/65535/' /etc/security/limits.d/20-nproc.conf
            fi
        fi
    fi
    ulimit -SHn 512000
    if grep -q "^ulimit" /etc/profile;then
        sed -i '/ulimit -SHn/d' /etc/profile
        echo -e "\nulimit -SHn 512000" >> /etc/profile
    else
        echo -e "\nulimit -SHn 512000" >> /etc/profile
    fi
    if ! grep -q "pam_limits.so" /etc/pam.d/common-session;then
        echo "session required pam_limits.so" >> /etc/pam.d/common-session
    fi
    if ! grep -q "pam_limits.so" /etc/pam.d/common-session-noninteractive;then
        echo "session required pam_limits.so" >> /etc/pam.d/common-session-noninteractive
    fi
    if grep -q "^DefaultLimitCORE" /etc/systemd/system.conf;then
        sed -i '/DefaultLimitCORE/d' /etc/systemd/system.conf
        echo "DefaultLimitCORE=infinity" >> /etc/systemd/system.conf
    else
        echo "DefaultLimitCORE=infinity" >> /etc/systemd/system.conf
    fi
    if grep -q "^DefaultLimitNOFILE" /etc/systemd/system.conf;then
        sed -i '/DefaultLimitNOFILE/d' /etc/systemd/system.conf
        echo "DefaultLimitNOFILE=512000" >> /etc/systemd/system.conf
    else
        echo "DefaultLimitNOFILE=512000" >> /etc/systemd/system.conf
    fi
    if grep -q "^DefaultLimitNPROC" /etc/systemd/system.conf;then
        sed -i '/DefaultLimitNPROC/d' /etc/systemd/system.conf
        echo "DefaultLimitNPROC=512000" >> /etc/systemd/system.conf
    else
        echo "DefaultLimitNPROC=512000" >> /etc/systemd/system.conf
    fi
    systemctl daemon-reload
    echo -e "${green}完成${plain}"
}

#优化sysctl.conf
set_sysctl(){
echo -e "${yellow}优化系统内核参数${plain}"
sed -i '/net.ipv4.icmp_echo_ignore_broadcasts/d' /etc/sysctl.conf
sed -i '/net.ipv4.icmp_ignore_bogus_error_responses/d' /etc/sysctl.conf
sed -i '/net.ipv4.conf.all.rp_filter/d' /etc/sysctl.conf
sed -i '/net.ipv4.conf.default.rp_filter/d' /etc/sysctl.conf
sed -i '/net.ipv4.conf.all.accept_source_route/d' /etc/sysctl.conf
sed -i '/net.ipv4.conf.default.accept_source_route/d' /etc/sysctl.conf
sed -i '/kernel.sysrq/d' /etc/sysctl.conf
sed -i '/kernel.core_uses_pid/d' /etc/sysctl.conf
sed -i '/net.ipv4.tcp_syncookies/d' /etc/sysctl.conf
sed -i '/kernel.msgmnb/d' /etc/sysctl.conf
sed -i '/kernel.msgmax/d' /etc/sysctl.conf
sed -i '/net.ipv4.tcp_max_tw_buckets/d' /etc/sysctl.conf
sed -i '/net.ipv4.tcp_sack/d' /etc/sysctl.conf
sed -i '/net.ipv4.tcp_fack/d' /etc/sysctl.conf
sed -i '/net.ipv4.tcp_window_scaling/d' /etc/sysctl.conf
sed -i '/net.ipv4.tcp_rmem/d' /etc/sysctl.conf
sed -i '/net.ipv4.tcp_wmem/d' /etc/sysctl.conf
sed -i '/net.core.wmem_default/d' /etc/sysctl.conf
sed -i '/net.core.rmem_default/d' /etc/sysctl.conf
sed -i '/net.core.rmem_max/d' /etc/sysctl.conf
sed -i '/net.core.wmem_max/d' /etc/sysctl.conf
sed -i '/net.ipv4.udp_rmem_min/d' /etc/sysctl.conf
sed -i '/net.ipv4.udp_wmem_min/d' /etc/sysctl.conf
sed -i '/net.core.netdev_max_backlog/d' /etc/sysctl.conf
sed -i '/net.ipv4.tcp_max_syn_backlog/d' /etc/sysctl.conf
sed -i '/net.ipv4.tcp_timestamps/d' /etc/sysctl.conf
sed -i '/net.ipv4.tcp_synack_retries/d' /etc/sysctl.conf
sed -i '/net.ipv4.tcp_syn_retries/d' /etc/sysctl.conf
sed -i '/net.ipv4.tcp_tw_recycle/d' /etc/sysctl.conf
sed -i '/net.ipv4.tcp_tw_reuse/d' /etc/sysctl.conf
sed -i '/net.ipv4.tcp_fin_timeout/d' /etc/sysctl.conf
sed -i '/net.ipv4.ip_local_port_range/d' /etc/sysctl.conf
sed -i '/net.ipv4.conf.all.accept_redirects/d' /etc/sysctl.conf
sed -i '/net.ipv4.conf.default.accept_redirects/d' /etc/sysctl.conf
sed -i '/net.ipv4.conf.all.secure_redirects/d' /etc/sysctl.conf
sed -i '/net.ipv4.conf.default.secure_redirects/d' /etc/sysctl.conf
sed -i '/net.ipv4.tcp_no_metrics_save/d' /etc/sysctl.conf
sed -i '/net.ipv4.tcp_moderate_rcvbuf/d' /etc/sysctl.conf
sed -i '/net.ipv4.tcp_retries2/d' /etc/sysctl.conf
sed -i '/net.ipv4.tcp_slow_start_after_idle/d' /etc/sysctl.conf
sed -i '/net.ipv4.route.gc_timeout/d' /etc/sysctl.conf
sed -i '/fs.file-max/d' /etc/sysctl.conf
sed -i '/fs.inotify.max_user_instances/d' /etc/sysctl.conf
sed -i '/vm.swappiness/d' /etc/sysctl.conf
sed -i '/net.core.somaxconn/d' /etc/sysctl.conf
sed -i '/net.ipv4.tcp_keepalive_time/d' /etc/sysctl.conf
sed -i '/net.ipv4.tcp_keepalive_probes/d' /etc/sysctl.conf
sed -i '/net.ipv4.tcp_keepalive_intvl/d' /etc/sysctl.conf
sed -i '/net.ipv4.tcp_fastopen/d' /etc/sysctl.conf
sed -i '/net.ipv4.tcp_mtu_probing/d' /etc/sysctl.conf
sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf
sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf
cat << EOF >> /etc/sysctl.conf
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
kernel.sysrq = 0
kernel.core_uses_pid = 1
net.ipv4.tcp_syncookies = 1
kernel.msgmnb = 65535
kernel.msgmax = 65535
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.tcp_sack = 1
net.ipv4.tcp_fack = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.core.wmem_default = 65536
net.core.rmem_default = 65536
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.udp_rmem_min=4096
net.ipv4.udp_wmem_min=4096
net.core.netdev_max_backlog = 4096
net.ipv4.tcp_max_syn_backlog = 4096
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 2
net.ipv4.tcp_tw_recycle = 0
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.ip_local_port_range = 16384 65535
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv4.tcp_no_metrics_save = 1
net.ipv4.tcp_moderate_rcvbuf = 1
net.ipv4.tcp_retries2 = 8
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.route.gc_timeout = 100
fs.file-max = 512000
fs.inotify.max_user_instances = 8192
vm.swappiness = 0
net.core.somaxconn = 4096
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.tcp_keepalive_intvl = 30
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_mtu_probing = 1
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
EOF
/sbin/sysctl -p /etc/sysctl.conf
/sbin/sysctl -w net.ipv4.route.flush=1
echo -e "${green}完成${plain}"
}

#优化系统熵值
set_entropy(){
    if [ `cat /proc/sys/kernel/random/entropy_avail` -lt 1000 ]; then
        echo -e "${yellow}优化系统熵值${plain}"
        if [[ x"${release}" == x"centos" ]]; then
            yum -y install haveged
            systemctl enable --now haveged
        elif [[ x"${release}" == x"ubuntu" ]]; then
            apt install -y haveged
            systemctl enable --now haveged
        elif [[ x"${release}" == x"debian" ]]; then
            apt install -y haveged
            systemctl enable --now haveged
        fi
        echo -e "${green}完成${plain}"

    fi
}

# 个性化vim编辑器
set_vimserver(){
    if [[ x"${release}" == x"centos" ]]; then
        if [ `grep -c "vim20210527" /etc/vimrc` -eq 0 ];then
            echo -e "${yellow}个性化vim编辑器${plain}"
cat << EOF >> /etc/vimrc
set cursorline
set autoindent
set showmode
set ruler
syntax on
filetype on
set smartindent
set tabstop=4
set shiftwidth=4
set hlsearch
set incsearch
set ignorecase
"vim20210527
EOF
            source /etc/bashrc
            echo -e "${green}完成${plain}"
        fi
    elif [[ x"${release}" == x"ubuntu" ]]; then
        if [ `grep -c "vim20210527" /etc/vim/vimrc` -eq 0 ];then
            echo -e "${yellow}个性化vim编辑器${plain}"
cat << EOF >> /etc/vim/vimrc
set cursorline
set autoindent
set showmode
set ruler
syntax on
filetype on
set smartindent
set tabstop=4
set shiftwidth=4
set hlsearch
set incsearch
set ignorecase
"vim20210527
EOF
            source /etc/bash.bashrc
            echo -e "${green}完成${plain}"
        fi
    elif [[ x"${release}" == x"debian" ]]; then
        if [ `grep -c "vim20210527" /etc/vim/vimrc` -eq 0 ];then
            echo -e "${yellow}个性化vim编辑器${plain}"
cat << EOF >> /etc/vim/vimrc
set cursorline
set autoindent
set showmode
set ruler
syntax on
filetype on
set smartindent
set tabstop=4
set shiftwidth=4
set hlsearch
set incsearch
set ignorecase
"vim20210527
EOF
            source /etc/bash.bashrc
            echo -e "${green}完成${plain}"
        fi
    fi
}

#优化journald服务
set_journal(){
    echo -e "${yellow}优化journald服务${plain}"
    [ -e /var/log/journal ] || mkdir /var/log/journal
    if grep -q "^Storage" /etc/systemd/journald.conf;then
        sed -i '/^Storage/s/auto/persistent/' /etc/systemd/journald.conf
    else
       sed -i '$a Storage=persistent' /etc/systemd/journald.conf
    fi
    if grep -q "^ForwardToSyslog" /etc/systemd/journald.conf;then
        sed -i '/^ForwardToSyslog/s/yes/no/' /etc/systemd/journald.conf
    else
       sed -i '$a ForwardToSyslog=no' /etc/systemd/journald.conf
    fi
    if grep -q "^ForwardToWall" /etc/systemd/journald.conf;then
        sed -i '/^ForwardToWall/s/yes/no/' /etc/systemd/journald.conf
    else
       sed -i '$a ForwardToWall=no' /etc/systemd/journald.conf
    fi
    if grep -q "^SystemMaxUse" /etc/systemd/journald.conf;then
        sed -i '/^SystemMaxUse/s/.*/SystemMaxUse=384M/' /etc/systemd/journald.conf
    else
       sed -i '$a SystemMaxUse=384M' /etc/systemd/journald.conf
    fi
    if grep -q "^SystemMaxFileSize" /etc/systemd/journald.conf;then
        sed -i '/^SystemMaxFileSize/s/.*/SystemMaxFileSize=128M/' /etc/systemd/journald.conf
    else
       sed -i '$a SystemMaxFileSize=128M' /etc/systemd/journald.conf
    fi
    systemctl restart systemd-journald
    echo -e "${green}完成${plain}"
}

#个性化快捷键
set_readlines(){
    echo -e "${yellow}个性化快捷键${plain}"
    if grep -q '^"\\e.*": history-search-backward' /etc/inputrc;then
        sed -i 's/^"\\e.*": history-search-backward/"\\e\[A": history-search-backward/g' /etc/inputrc
    else
        sed -i '$a # map "up arrow" to search the history based on lead characters typed' /etc/inputrc
        sed -i '$a "\\e\[A": history-search-backward' /etc/inputrc
    fi
    if grep -q '^"\\e.*": history-search-forward' /etc/inputrc;then
        sed -i 's/^"\\e.*": history-search-forward/"\\e\[B": history-search-forward/g' /etc/inputrc
    else
        sed -i '$a # map "down arrow" to search history based on lead characters typed' /etc/inputrc
        sed -i '$a "\\e\[B": history-search-forward' /etc/inputrc
    fi
    if grep -q '"\\e.*": kill-word' /etc/inputrc;then
        sed -i 's/"\\e.*": kill-word/"\\e[3;3~": kill-word/g' /etc/inputrc
    else
        sed -i '$a # map ALT+Delete to remove word forward' /etc/inputrc
        sed -i '$a "\\e[3;3~": kill-word' /etc/inputrc
    fi
    echo -e "${green}完成${plain}"
}

#Centos增加virtio-blk和xen-blkfront外置驱动
set_drivers(){
    if [[ x"${release}" == x"centos" ]]; then
        echo -e "${yellow}优化外置驱动${plain}"
        if [ ! -e /etc/dracut.conf.d/virt-drivers.conf ];then
            echo 'add_drivers+="xen-blkfront virtio_blk"' >> /etc/dracut.conf.d/virt-drivers.conf
        else
            if ! grep -wq "xen-blkfront" /etc/dracut.conf.d/virt-drivers.conf;then
                echo 'add_drivers+="xen-blkfront virtio_blk"' >> /etc/dracut.conf.d/virt-drivers.conf
            fi
        fi
        echo -e "${green}完成${plain}"
    fi
}

#个性化登录展示
set_welcome(){
    echo -e "${yellow}个性化登录展示${plain}"
    if [ ! -e /etc/profile.d/motd.sh ];then
        wget -O /etc/profile.d/motd.sh https://${GITHUB_RAW_URL}/myxuchangbin/shellscript/master/motd.sh
        chmod a+x /etc/profile.d/motd.sh
    fi
    echo -e "${green}完成${plain}"
}

main(){
    install
    set_securite
    set_file
    set_sysctl
    set_entropy
    set_vimserver
    set_journal
    set_readlines
    set_drivers
    set_welcome
}
main

rm -f startsys.sh && history -c
echo -e "修改登录欢迎 \033[47;30;5m vi /etc/profile.d/motd.sh \033[0m  " 
