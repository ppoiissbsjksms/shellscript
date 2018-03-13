#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

#domain="xmr-eu1 xmr-eu2 xmr-us-east1 xmr-us-west1 xmr-asia1 xmr-jp1 xmr-au1"
#for i in $domain
#do
#    ip=${i}.nanopool.org
#    echo "====================$ip===================="
#    ping -c 4 $ip
#    echo ""
#done

#> ping.pl
#domain="xmr-eu1 xmr-eu2 xmr-us-east1 xmr-us-west1 xmr-asia1 xmr-jp1 xmr-au1"
#for i in $domain
#do
#    ip=${i}.nanopool.org
#    ping=`ping -c 1 -w 1 $ip |grep time=|awk '{print $8}'|sed "s/time=//"`
#    echo "${ping} ${ip}" >> ping.pl
#done
#pool`sort -V ping.pl|sed -n '1p'|awk '{print $2}'`
#echo "延迟最低：${pool}，端口14433，支持SSL"
#echo "钱包地址：44rugoDVTkhgtZnm6sLAxiXSAy9fwSP1H55hd2DeG9YPNqqDPVe8PdcjXqrT3anyZ22j7DEE74GkbVcQFyH2nNiC3hkE1bw"
#echo "密码：x"

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

is_64bit() {
    if [ `getconf WORD_BIT` = '32' ] && [ `getconf LONG_BIT` = '64' ] ; then
        return 0
    else
        return 1
    fi
}

install_cuda() {
    lspci | grep -i nvidia
    if [ $? -eq 0 ]; then
        if [ ! -f /usr/local/cuda/bin/nvcc ]; then
            yum install -y kernel-devel-$(uname -r) kernel-headers-$(uname -r) dkms gcc gcc-c++
            # install Cuda 8.0+ https://developer.nvidia.com/cuda-downloads
            if centosversion 6; then
                rpm -ivh http://developer.download.nvidia.com/compute/cuda/repos/rhel6/x86_64/cuda-repo-rhel6-9.1.85-1.x86_64.rpm
                yum clean all
                yum install cuda -y
            elif centosversion 7; then
                rpm -ivh http://developer.download.nvidia.com/compute/cuda/repos/rhel7/x86_64/cuda-repo-rhel7-9.1.85-1.x86_64.rpm
                yum clean all
                yum install cuda -y
            fi
            grep "/usr/local/cuda/bin" /etc/profile
            if [ $? -ne 0 ]; then
                echo -ne '\nexport PATH=$PATH:/usr/local/cuda/bin\n' >> /etc/profile
                source /etc/profile
            fi
            nvcc -V
            if [ $? -eq 0 ]; then
                echo -e "[${green}Info${plain}] CUDA successfully installed, restart the computer to take effect."
            else
                echo -e "[${red}Error${plain}] CUDA installation failed."
            fi
            
        else
            echo -e "[${green}Info${plain}] CUDA already installed."
        fi
    else
        echo -e "[${red}Error${plain}] Please confirm whether the machine is equipped with CUDA support GPU."
    fi
}

install_amd_app_sdk() {
    lspci | grep -i amd
    if [ $? -eq 0 ]; then
        if [ ! -e /opt/AMDAPPSDK-3.0 ]; then
            # install AMD APP SDK 3.0 http://developer.amd.com/amd-accelerated-parallel-processing-app-sdk/
            clear
            echo -e "[${green}Info${plain}] AMD APP SDK installation requires you to manually confirm some information, do not go away."
            sleep 15
            if is_64bit; then
                wget http://xuchangbin-10064044.file.myqcloud.com/download/amd-app-sdk/AMD-APP-SDKInstaller-v3.0.130.136-GA-linux64.tar.bz2
                tar xvf AMD-APP-SDKInstaller-v3.0.130.136-GA-linux64.tar.bz2
                ./AMD-APP-SDK-v3.0.130.136-GA-linux64.sh
            else
                wget http://xuchangbin-10064044.file.myqcloud.com/download/amd-app-sdk/AMD-APP-SDKInstaller-v3.0.130.136-GA-linux32.tar.bz2
                tar xvf AMD-APP-SDKInstaller-v3.0.130.136-GA-linux32.tar.bz2
                ./AMD-APP-SDK-v3.0.130.136-GA-linux32.sh
            fi
        else
            echo -e "[${green}Info${plain}] AMD APP SDK already installed."
        fi
    else
        echo -e "[${red}Error${plain}] Please confirm whether the machine is equipped with AMD APP SDK support GPU."
    fi
}

install_check() {
    if check_sys packageManager yum ; then
        if centosversion 5; then
            return 1
        fi
        return 0
    else
        return 1
    fi
}

if ! install_check; then
    echo -e "[${red}Error${plain}] Your OS is not supported to run it!"
    echo "Please change to CentOS 6+ and try again."
    exit 1
fi

if [ -s /etc/selinux/config ] && grep 'SELINUX=enforcing' /etc/selinux/config; then
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    setenforce 0
fi

if [[ -f /etc/security/limits.conf ]]; then
    sed -i '/^\(\*\|root\).*\(hard\|soft\).*nofile/d' /etc/security/limits.conf
    echo -ne "*\thard\tnofile\t512000\n*\tsoft\tnofile\t512000\nroot\thard\tnofile\t512000\nroot\tsoft\tnofile\t512000\n" >> /etc/security/limits.conf
fi
if [[ -f /etc/sysctl.conf ]]; then
    sed -i '/^fs.file-max.*/d' /etc/sysctl.conf
    sed -i '/^vm.nr_hugepages.*/d' /etc/sysctl.conf
    echo -ne '\nvm.nr_hugepages=128\n' >>/etc/sysctl.conf
    echo -ne '\nfs.file-max=512000\n' >>/etc/sysctl.conf
fi
grep "* soft memlock 262144" /etc/security/limits.conf
if [ $? -ne 0 ]; then
    echo "* soft memlock 262144" >> /etc/security/limits.conf
    echo "* hard memlock 262144" >> /etc/security/limits.conf
fi
yum install centos-release-scl epel-release -y
yum install hwloc-devel libmicrohttpd-devel openssl-devel make cmake cmake3 devtoolset-4-gcc* git screen lrzsz bzip2 pciutils -y
if [ -e "xmr-stak" ]; then
    rm -rf xmr-stak
fi
git clone https://github.com/fireice-uk/xmr-stak.git
mkdir xmr-stak/build && cd xmr-stak/build
grep "2.0 / 100.0" ../xmrstak/donate-level.hpp
if [ $? -eq 0 ]; then
    sed -i 's/2.0 \/ 100.0/0.0 \/ 100.0/g' ../xmrstak/donate-level.hpp
fi

mode=(cpu nvidia amd all)
while true
do
echo  "Which mode you choose to install xmr-stak:"
for ((i=1;i<=${#mode[@]};i++ )); do
    hint="${mode[$i-1]}"
    echo -e "${green}${i}${plain} ) ${hint}"
done
read -p "Please enter a number (Default ${mode[0]}):" selected
[ -z "${selected}" ] && selected="1"
case "${selected}" in
    1|2|3|4)
    echo
    echo "You choose = ${mode[${selected}-1]}"
    echo
    break
    ;;
    *)
    echo -e "[${red}Error${plain}] Please only enter a number [1-3]"
    ;;
esac
done

if   [ "${selected}" == "1" ]; then
    # cpu
    scl enable devtoolset-4 'cmake3 .. -DCUDA_ENABLE=OFF -DOpenCL_ENABLE=OFF'
elif [ "${selected}" == "2" ]; then
    # nvidia
    install_cuda
    scl enable devtoolset-4 'cmake3 .. -DOpenCL_ENABLE=OFF'
elif [ "${selected}" == "3" ]; then
    # amd
    install_amd_app_sdk
    scl enable devtoolset-4 'cmake3 .. -DCUDA_ENABLE=OFF'
elif [ "${selected}" == "4" ]; then
    # cpu and nvidia and amd
    install_cuda
    install_amd_app_sdk
    scl enable devtoolset-4 'cmake3 ..'
fi
#cmake3 .. -DCUDA_ENABLE=OFF -DOpenCL_ENABLE=OFF
#cmake3 .. -DOpenCL_ENABLE=OFF
make install
if [ $? -eq 0 ]; then
    echo -e "[${green}Info${plain}] xmr-stak successfully installed, Run: cd xmr-stak/build/bin/ ; ./xmr-stak"
else
    rm -rf ./*
    echo -e "[${red}Error${plain}] xmr-stak installation failed, Please try again"
fi
