#!/usr/bin/env bash
#Uses: 仅适用centos7/8
#date: 2021-04-02

# 判断Centos系统版本
sysVersion=`cat /etc/redhat-release|sed -r 's/.* ([0-9]+)\..*/\1/'`

GITHUB_RAW_URL="raw.githubusercontent.com"
GITHUB_URL="github.com"
if [ -n "$1" ]; then
    if echo "$1" | grep -qwi "cn"; then
        GITHUB_RAW_URL="raw.fastgit.org"
        GITHUB_URL="hub.fastgit.org"
    fi
fi
#安装必要软件
install(){
        echo "安装软件包"
        yum clean all
        # centos7
        if [ $sysVersion -eq 7 ]; then
            yum -y install epel-release.noarch 
            yum -y install vim wget curl zip unzip bash-completion git tree mlocate lrzsz libsodium tar lsof nmap nload tcping hping3 screen nano python-devel python-pip python3-devel python3-pip socat nc ioping mtr bind-utils yum-utils ntpdate gcc gcc-c++ make iftop traceroute net-tools fping vnstat pciutils iperf3 iotop htop sysstat tcpdump bc cmake openssl-devel systemd sudo
        fi
        # centos8
        if [ $sysVersion -eq 8 ]; then
            dnf -y install epel-release
            dnf -y install vim wget curl zip unzip bash-completion git tree mlocate lrzsz libsodium tar lsof nmap nload tcping hping3 screen nano python2-devel python2-pip python3-devel python3-pip socat nc ioping mtr bind-utils yum-utils gcc gcc-c++ make iftop traceroute net-tools fping vnstat pciutils iperf3 iotop htop sysstat tcpdump bc cmake openssl-devel systemd sudo
        fi

}

#安全设置
set_securite(){
    echo "关闭SeLinux"
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
    echo "添加SSH个人秘钥"
        [ -e /root/.ssh ] || mkdir -p /root/.ssh
        [ -e /root/.ssh/authorized_keys ] || touch /root/.ssh/authorized_keys
        if [ `grep -c "#pkey20210402" /root/.ssh/authorized_keys` -eq 0 ];then
            wget -O /tmp/id_rsa_1024.pub https://${GITHUB_RAW_URL}/myxuchangbin/shellscript/master/id_rsa_1024.pub
            if echo "03533eeb543c816baab80ef55330eca9  /tmp/id_rsa_1024.pub" | md5sum -c; then
                cat /tmp/id_rsa_1024.pub >> /root/.ssh/authorized_keys
                echo -e "\n#pkey20210402" >> /root/.ssh/authorized_keys
            fi
            rm -f /tmp/id_rsa_1024.pub
        fi
    echo "同步时区"
        if [ $sysVersion -eq 7 ]; then
            if [ `timedatectl | grep "Time zone" | grep -c "Asia/Shanghai"` -eq 0 ];then
                timedatectl set-timezone Asia/Shanghai
                sed -i 's%SYNC_HWCLOCK=no%SYNC_HWCLOCK=yes%' /etc/sysconfig/ntpdate
            fi
            ntpdate ntp.aliyun.com
            hwclock -w
        fi
        #  centos-8:
        if [ $sysVersion -eq 8 ]; then
            if [ `timedatectl | grep "Time zone" | grep -c "Asia/Shanghai"` -eq 0 ];then
                timedatectl set-timezone Asia/Shanghai
                echo "server ntp.aliyun.com iburst" >>/etc/chrony.conf
                echo "server ntp.7io.com iburst" >>/etc/chrony.conf
                systemctl restart chronyd.service
                chronyc sources -v 
            fi
        fi
    echo "history"
        if [ `grep -c "#history20210402" /etc/profile` -eq 0 ];then
            echo "export HISTTIMEFORMAT=\"%F %T \`whoami\` \" #history20210402" >> /etc/profile
        fi
    echo "禁止键盘重启系统命令"
        rm -rf /usr/lib/systemd/system/ctrl-alt-del.target
    echo "设置字符集"
        localedef -c -f UTF-8 -i zh_CN zh_CN.UTF-8
        export LC_ALL=zh_CN.UTF-8
        if grep -q "^LANG" /etc/locale.conf;then
            sed -i '/^LANG=/s/.*/LANG=zh_CN.UTF-8/' /etc/locale.conf
        else
           sed -i '$a LANG=zh_CN.UTF-8' /etc/locale.conf
        fi
    echo "设置每天6点释放内存"
        if [ `grep -c "#crontab20210402" /etc/crontab` -eq 0 ];then
            echo -e "0 6 * * * root sync; echo 3 > /proc/sys/vm/drop_caches \n#crontab20210402" >> /etc/crontab
        fi
}

#设置文件句柄和进程
set_file(){
    if [ `grep -c "#limits20210402" /etc/security/limits.conf` -eq 0 ];then
        echo "root soft nofile 512000" >> /etc/security/limits.conf
        echo "root hard nofile 512000" >> /etc/security/limits.conf
        echo "* soft nofile 512000" >> /etc/security/limits.conf
        echo "* hard nofile 512000" >> /etc/security/limits.conf
        echo "* soft nproc  512000" >> /etc/security/limits.conf
        echo "* hard nproc  512000" >> /etc/security/limits.conf
        echo -e "\n#limits20210402" >> /etc/security/limits.conf
    fi
    if [ $sysVersion -eq 7 ]; then
        sed -i 's/4096/65535/' /etc/security/limits.d/20-nproc.conf
    fi
    ulimit -SHn 512000
}

#sysctl.conf 设置
set_sysctl(){
if [ `grep -c "#sysctl20210402" /etc/sysctl.conf` -eq 0 ];then
cat << EOF >> /etc/sysctl.conf
#预防ICMP探测
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
#对直接连接的网络进行反向路径过滤
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
#不允许接受含有源路由信息的ip包
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
#关闭sysrq功能
kernel.sysrq = 0
#core文件名中添加pid作为扩展名
kernel.core_uses_pid = 1
#开启SYN洪水攻击保护
net.ipv4.tcp_syncookies = 1
#修改消息队列长度
kernel.msgmnb = 65535
kernel.msgmax = 65535
#timewait的数量，默认180000
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.tcp_sack = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 87380 67108864
net.core.wmem_default = 65536
net.core.rmem_default = 65536
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
#每个网络接口接收数据包的速率比内核处理这些包的速率快时，允许送到队列的数据包的最大数目
net.core.netdev_max_backlog = 4096
#未收到客户端确认信息的连接请求的最大值
net.ipv4.tcp_max_syn_backlog = 4096
net.ipv4.tcp_timestamps = 0
#SYN的重试次数，适当降低该值，有助于防范SYN攻击
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 2
#关闭timewait 快速回收
net.ipv4.tcp_tw_recycle = 0
#开启重用。
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 30
#允许系统打开的端口范围
net.ipv4.ip_local_port_range = 1024 65000
# 确保无人能修改路由表
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
#
net.ipv4.tcp_no_metrics_save = 1
#net.ipv4.tcp_moderate_rcvbuf = 1
net.ipv4.tcp_retries2 = 8
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.route.gc_timeout = 100
fs.file-max = 512000
fs.inotify.max_user_instances = 8192
vm.swappiness = 0
net.core.somaxconn = 4096
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_mtu_probing = 1
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
#sysctl20210402
EOF
/sbin/sysctl -p /etc/sysctl.conf  
/sbin/sysctl -w net.ipv4.route.flush=1
fi
}

#系统熵值优化
set_entropy(){
    if [ `cat /proc/sys/kernel/random/entropy_avail` -lt 1000 ]; then
        yum -y install haveged
        systemctl enable --now haveged
    fi
}

# 配置vim编辑器
set_VimServer(){
    if [ `grep -c "vim20210402" /etc/vimrc` -eq 0 ];then
        echo "设置Vim编辑器"
        echo "set cursorline" >>/etc/vimrc
        echo "set autoindent" >>/etc/vimrc
        echo "set showmode" >>/etc/vimrc
        echo "set ruler" >>/etc/vimrc
        echo "syntax on" >>/etc/vimrc
        echo "filetype on" >>/etc/vimrc
        echo "set smartindent" >>/etc/vimrc
        echo "set tabstop=4" >>/etc/vimrc
        echo "set shiftwidth=4" >>/etc/vimrc
        echo "set hlsearch" >>/etc/vimrc
        echo "set incsearch" >>/etc/vimrc
        echo "set ignorecase" >>/etc/vimrc
        echo -e "\n\"vim20210402" >>/etc/vimrc

        source /etc/bashrc
    fi
}

set_journal(){
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
}

# 设置登陆提示
set_welcome(){
    if [ ! -e /etc/profile.d/motd.sh ];then
        wget -O /etc/profile.d/motd.sh https://${GITHUB_RAW_URL}/myxuchangbin/shellscript/master/motd.sh
        chmod a+x /etc/profile.d/motd.sh
    fi
}

main(){
    install
    set_securite
    set_file
    set_sysctl
    set_entropy
    set_VimServer
    set_journal
    set_welcome
}
main

rm -rf StartSys.sh && history -c
echo -e "修改登录欢迎 \033[47;30;5m vi /etc/profile.d/motd.sh \033[0m  " 
