# 一些收藏和随手写的脚本

switchkernel.sh
======

- 脚本说明: CentOS一键更换内核脚本，CentOS6 内核更换为： 2.6.32-642.el6.x86_64，CentOS7 内核更换为： 3.10.0-229.1.2.el7.x86_64
- 系统支持: CentOS6/7
- 内核说明: 匹配锐速的最新相应内核版本

### 下载安装:
``` bash
wget -N --no-check-certificate https://raw.githubusercontent.com/myxuchangbin/shellscript/master/switchkernel.sh && chmod +x bbr.sh && bash switchkernel.sh
```
mysqld-listen.sh
======

- 脚本说明: 监控mysql进程，当mysql死掉自动启动之
- 系统支持: Linux

### 使用方法:
``` bash
wget -N --no-check-certificate https://raw.githubusercontent.com/myxuchangbin/shellscript/master/mysqld-listen.sh && chmod +x mysqld-listen.sh

crontab -e
*/5 * * * *    mysqld-listen.sh    #每隔5分钟，执行一次mysqld-listen.sh脚本。
```
xmrig-proxy
======

- 脚本说明: xmrig-proxy启动脚本，一键切换coin钱包
- 系统支持: Ubuntu12+ CentOS6+
- 使用说明: 使用前请自行修改脚本中相关配置信息