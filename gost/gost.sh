#!/usr/bin/env bash
# Wiki: https://v2.gost.run/
# Usage: bash <(curl -s https://raw.githubusercontent.com/myxuchangbin/shellscript/master/gost/gost.sh)
# Uninstall: systemctl stop gost; systemctl disable gost; rm -rf /etc/systemd/system/gost.service /opt/gost

GITHUB_RAW_URL="raw.githubusercontent.com"
GITHUB_URL="github.com"
CN=0
if [ -n "$1" ]; then
    if echo "$1" | grep -qwi "cn"; then
        CN=1
        GITHUB_RAW_URL="raw.fastgit.org"
        GITHUB_URL="hub.fastgit.org"
    fi
fi
if [ ${CN} == 1 ]; then
    URL="https://ghproxy.com/https://github.com$(wget -qO- "https://ghproxy.com/https://github.com/ginuerzh/gost/releases/latest" | grep -E "href=.*gost-linux-amd64" | awk -F "\"" '{print $2}')"
else
    URL="$(wget -qO- https://api.github.com/repos/ginuerzh/gost/releases/latest | grep -E "browser_download_url.*gost-linux-amd64" | cut -f4 -d\")"
fi
[ -e /opt/gost/ ] || mkdir -p /opt/gost/
[ -e /opt/gost/config.json ] || wget https://${GITHUB_RAW_URL}/myxuchangbin/shellscript/master/gost/config.json -O /opt/gost/config.json
[ -e /opt/gost/gost ] && rm -rf /opt/gost/gost
wget -O - $URL | gzip -d > /opt/gost/gost && chmod +x /opt/gost/gost
tmpdomain=`echo $RANDOM | md5sum | cut -c1-8`
openssl req -newkey rsa:4096 \
            -x509 \
            -sha256 \
            -days 3650 \
            -nodes \
            -out /opt/gost/cert.pem \
            -keyout /opt/gost/key.pem \
            -subj "/C=US/ST=Alabama/L=Montgomery/O=Super Shops/OU=Marketing/CN=www.${tmpdomain}.com"

cat <<EOF > /etc/systemd/system/gost.service
[Unit]
Description=Gost server
After=network-online.target
Wants=network-online.target

[Service]
LimitCORE=infinity
LimitNOFILE=512000
LimitNPROC=512000
Type=simple
DynamicUser=yes
StandardOutput=null
#StandardError=journal
WorkingDirectory=/opt/gost
ExecStart=/opt/gost/gost -C /opt/gost/config.json
User=root
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

crontab -l > /tmp/gostcronconf
if grep -wq "gost.service" /tmp/gostcronconf;then
  sed -i "/gost.service/d" /tmp/gostcronconf
fi
echo "3 6 * * *  /usr/bin/systemctl restart gost.service" >> /tmp/gostcronconf
crontab /tmp/gostcronconf
rm -f /tmp/gostcronconf
echo -e "定时任务设置成功！每天6点3分重启gost服务"

systemctl daemon-reload
systemctl enable gost.service --now
