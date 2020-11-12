#!/bin/bash
#########################################################################
# File Name: motd.sh
# Author: xcbin
# Blog: https://www.91linux.org
# Created Time: 2020年11月12日
#########################################################################

#
# Logo
#

logo='
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


                                        The image is made by @xcbin
'

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
# Time
#

time_cur=$(date)

#
# Users
#

user_num=$(who -u | wc -l)

echo -e "\033[0;36;40m$logo\033[0m"
echo -e "系统时间: \t$time_cur"
echo -e "内存使用: \t\033[0;31;40m$mem_used\033[0m MiB / \033[0;32;40m$mem_total\033[0m MiB ($mem_usage%)"
echo -e "平均负载: \t\033[0;33;40m$load_average\033[0m"
echo -e "在线用户: \t$user_num\n"
