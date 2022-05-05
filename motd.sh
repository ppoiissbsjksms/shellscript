#!/bin/bash
#########################################################################
# File Name: motd.sh
# Author: xcbin
# Blog: https://www.91linux.org
# Created Time: 2022.04.18
#########################################################################

# Don't change! We want predictable outputs
export LANG="en_US.UTF-8"

#
# Logo
#

logo[1]="
                  !         !
                 ! !       ! !
                ! . !     ! . !
                   ^^^^^^^^^ ^
                 ^             ^
               ^  (0)       (0)  ^
              ^        ""         ^
             ^   ***************    ^
           ^   *                 *   ^
          ^   *   /\   /\   /\    *    ^
         ^   *                     *    ^
        ^   *   /\   /\   /\   /\   *    ^
       ^   *                         *    ^
       ^  *                           *   ^
       ^  *                           *   ^
        ^ *                           *  ^  
         ^*                           * ^ 
          ^ *                        * ^
          ^  *                      *  ^
            ^  *       ) (         * ^
                ^^^^^^^^ ^^^^^^^^^

        大部分人都在关注你飞的高不高，却没人在乎你飞的累不累，这就是现实！
            我从不相信梦想，我，只，相，信，自，己！
                                                    @xcbin
"
logo[2]="
       ┏┓ 　┏┓+ +
　　　┏┛┻━━━┛┻┓ + +
　　　┃ 　　　┃
　　　┃　━　　┃ ++ + + +
　　 ███━███  ┃+
　　　┃　 　　┃ +
　　　┃　┻　　┃
　　　┃　 　　┃ + +
　　　┗━┓ 　┏━┛
　　　　┃ 　┃
　　　　┃ 　┃ + + + +
　　　　┃ 　┃
　　　　┃ 　┃ + 　　神兽保佑,永不宕机！
　　　　┃ 　┃
　　　　┃ 　┃　　+
　　　　┃ 　┗━━━┓ + +
　　　　┃ 　　　┣┓
　　　　┃　 　　┏┛
　　　　┗┓┓┏━┳┓┏┛ + + + +
　　 　　┃┫┫ ┃┫┫
　　 　　┗┻┛ ┗┻┛+ + + +
"
logo[3]="
  　　┏┓ 　┏┓
 　　┏┛┻━━━┛┻┓
 　　┃　　　 ┃
 　　┃ 　━　 ┃
 　　┃ ┳┛　┗┳┃
 　　┃　　　 ┃
 　　┃ 　┻　 ┃
 　　┃　　　 ┃
 　　┗━┓ 　┏━┛
 　　　┃ 　┃    神兽保佑,永不宕机！
 　　　┃ 　┃
 　　　┃ 　┗━━━┓
 　　　┃　　　 ┣┓
 　　　┃　　　 ┏┛
 　　　┗┓┓┏━┳┓┏┛
 　 　　┃┫┫ ┃┫┫
 　 　　┗┻┛ ┗┻┛
"
logo[4]="
                       .::::.
                     .::::::::.
                    :::::::::::
                 ..:::::::::::'
              '::::::::::::'
                .::::::::::
           '::::::::::::::..
                ..::::::::::::.
                ::::::::::::::::
               ::::'':::::::::'        .:::.
              ::::'   ':::::'       .::::::::.
            .::::'      ::::     .:::::::'::::.
           .:::'       :::::  .:::::::::' ':::::.
          .::'        :::::.:::::::::'      ':::::.
         .::'         ::::::::::::::'         ''::::.
     ...:::           ::::::::::::'              ''::.
    '''' ':.          ':::::::::'                  ::::..
                       '.:::::'                    ':'''''..

           女神保佑，永不宕机！
"
logo=${logo[$[$RANDOM % ${#logo[@]} + 1]]}

#
# System
#

system_os=$(grep -w PRETTY_NAME /etc/os-release|awk -F '"' '{printf $2}')

#
# Kernel
#

kernel_version=$(uname -r)

#
# Memory
#
# MemUsed = Memtotal + Shmem - MemFree - Buffers - Cached - SReclaimable
# Source: https://github.com/KittyKatt/screenFetch/issues/386#issuecomment-249312716

mem_info=$(</proc/meminfo)
mem_total=$(awk '$1=="MemTotal:" {print $2}' <<< ${mem_info})
mem_used=$((${mem_total} + $(cat /proc/meminfo | awk '$1=="Shmem:" {print $2}')))
mem_used=$((${mem_used} - $(cat /proc/meminfo | awk '$1=="MemFree:" {print $2}')))
mem_used=$((${mem_used} - $(cat /proc/meminfo | awk '$1=="Buffers:" {print $2}')))
mem_used=$((${mem_used} - $(cat /proc/meminfo | awk '$1=="Cached:" {print $2}')))
mem_used=$((${mem_used} - $(cat /proc/meminfo | awk '$1=="SReclaimable:" {print $2}')))

mem_total=$((mem_total / 1024))
mem_used=$((mem_used / 1024))
mem_usage=$((100 * ${mem_used} / ${mem_total}))

#
# Load average
#

load_average=$(awk '{print $1" "$2" "$3}' /proc/loadavg)

#
# Disk
#

disk_used=$(df -h | grep " /$" | cut -f4 | awk '{printf "%s / %s (%s)", $3, $2, $5}')

#
# Time
#

time_cur=$(date +"%A, %e %B %Y, %r")

#
# Uptime
#

up_time=$(uptime | sed 's/,//g' | awk '{ print $3,$4,$5}')

#
# Username
#

user=${USER:-$(id -un)}
hostname=${HOSTNAME:-$(hostname)}

#
# Users
#

user_num=$(who -u | wc -l)

echo -e "\033[0;36;40m$logo\033[0m"
echo -e "操作系统: \t$system_os Kernel-$kernel_version"
echo -e "系统时间: \t$time_cur"
echo -e "运行时间: \t$up_time"
echo -e "系统负载: \t\033[0;33;40m$load_average\033[0m"
echo -e "内存使用: \t\033[0;31;40m$mem_used\033[0m MiB / \033[0;32;40m$mem_total\033[0m MiB ($mem_usage%)"
echo -e "磁盘使用: \t$disk_used"
echo -e "当前登录: \t$user@$hostname"
echo -e "在线用户: \t${user_num}\n"
