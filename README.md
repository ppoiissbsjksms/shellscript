# 一些收藏和随手写的脚本

## switchkernel.sh

- 脚本说明: CentOS一键更换内核脚本，CentOS6 内核更换为： 2.6.32-642.el6.x86_64，CentOS7 内核更换为： 3.10.0-229.1.2.el7.x86_64
- 系统支持: CentOS6/7
- 内核说明: 匹配锐速的最新相应内核版本

### 使用方法：
``` bash
wget -N --no-check-certificate https://raw.githubusercontent.com/myxuchangbin/shellscript/master/switchkernel.sh && chmod +x bbr.sh && bash switchkernel.sh
```
## mysqld-listen.sh

- 脚本说明: 监控mysql进程，当mysql死掉自动启动之
- 系统支持: Linux

### 使用方法：
``` bash
wget -N --no-check-certificate https://raw.githubusercontent.com/myxuchangbin/shellscript/master/mysqld-listen.sh && chmod +x mysqld-listen.sh
crontab -e
*/5 * * * *    mysqld-listen.sh    #每隔5分钟，执行一次mysqld-listen.sh脚本。
```
## xmrig-proxy

- 脚本说明: xmrig-proxy启动脚本，一键切换coin钱包
- 系统支持: Ubuntu12+ CentOS6+
- 使用说明: 使用前请自行修改脚本中相关配置信息

### 使用方法：
``` bash
wget -N --no-check-certificate https://raw.githubusercontent.com/myxuchangbin/shellscript/master/xmrig-proxy/xmrig-proxy.sh && chmod +x xmrig-proxy.sh
bash xmrig-proxy.sh
```

## xmr-stak.sh

- 脚本说明: 一键安装xmr-stak
- 系统支持: CentOS6+ （暂不支持其他系统）

### 使用方法：
``` bash
wget -N --no-check-certificate https://raw.githubusercontent.com/myxuchangbin/shellscript/master/xmr-stak.sh && chmod +x xmr-stak.sh && bash xmr-stak.sh
```

## xmrig-proxy.patch

- 脚本说明: XMRig Proxy without donate
- 适用版本: xmrig-proxy v2.6.3

### 使用方法：

``` bash
yum install -y patch git cmake cmake3 gcc gcc-c++ libuv-static libstdc++-static libuuid-devel libmicrohttpd-devel
git clone https://github.com/xmrig/xmrig-proxy.git
wget -N --no-check-certificate https://raw.githubusercontent.com/myxuchangbin/shellscript/master/xmrig-proxy.patch
patch -p0 < xmrig-proxy.patch
cd xmrig-proxy && mkdir build && cd build
cmake3 .. && make
rm -rf CM* Makefile cmake_install.cmake
cp ../src/config.json ./
```

## 解锁Netflix

### 条件：
- 可看Netflix的VPS
- [sniproxy](https://github.com/dlundquist/sniproxy)
- [dnsmasq](http://www.thekelleys.org.uk/dnsmasq/doc.html)
- 【可选】iptables/firewalld 用来限制ip访问

### 使用方法：
1. 根据官方文档安装好sniproxy，配置文件请参考`netfilx-proxy/sniproxy.conf`
2. 安装dnsmasq，配置文件请参考`netfilx-proxy/dnsmasq.conf`
3. 一般为了防止代理被滥用可使用防火墙来允许指定ip访问
   * firewalld
   ``` bash
   firewall-cmd --permanent --remove-service=http
   firewall-cmd --permanent --remove-service=https
   firewall-cmd --permanent --remove-service=dns
   firewall-cmd --permanent --remove-port=80/tcp
   firewall-cmd --permanent --remove-port=443/tcp
   firewall-cmd --permanent --remove-port=53/tcp
   firewall-cmd --permanent --remove-port=53/udp
   firewall-cmd --permanent --add-rich-rule="rule family="ipv4" source address="192.168.1.66" port protocol="tcp" port="80" accept"
   firewall-cmd --permanent --add-rich-rule="rule family="ipv4" source address="192.168.1.66" port protocol="tcp" port="443" accept"
   firewall-cmd --permanent --add-rich-rule="rule family="ipv4" source address="192.168.1.66" port protocol="tcp" port="53" accept"
   firewall-cmd --permanent --add-rich-rule="rule family="ipv4" source address="192.168.1.66" port protocol="udp" port="53" accept"
   firewall-cmd --reload
   ```
   **删除规则把`--add-rich-rule`改成`--remove-rich-rule`即可**
   * iptables
   ``` bash
   iptables -I INPUT -p tcp --dport 80 -j DROP
   iptables -I INPUT -p tcp --dport 443 -j DROP
   iptables -I INPUT -p tcp --dport 53 -j DROP
   iptables -I INPUT -p udp --dport 53 -j DROP
   iptables -I INPUT -s 10.10.10.20 -p tcp --dport 80 -j ACCEPT
   iptables -I INPUT -s 10.10.10.20 -p tcp --dport 443 -j ACCEPT
   iptables -I INPUT -s 10.10.10.20 -p tcp --dport 53 -j ACCEPT
   iptables -I INPUT -s 10.10.10.20 -p udp --dport 53 -j ACCEPT
   service iptables save
   service iptables restart
   ```
   **删除规则先执行`iptables -L INPUT -line-numbers`以序号形式列出，然后执行`iptables -D INPUT 1`删除指定序号规则**
---
***更多内容持续更新中...***
