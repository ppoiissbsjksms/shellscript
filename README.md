# 一些收藏和随手写的脚本

switchkernel.sh
======

- 脚本说明: CentOS一键更换内核脚本，CentOS6 内核更换为： 2.6.32-642.el6.x86_64，CentOS7 内核更换为： 3.10.0-229.1.2.el7.x86_64
- 系统支持: Debian6/7
- 内核说明: 匹配锐速的最新相应内核版本

### 下载安装:
``` bash
wget -N --no-check-certificate https://raw.githubusercontent.com/myxuchangbin/shellscript/master/switchkernel.sh && chmod +x bbr.sh && bash switchkernel.sh
```