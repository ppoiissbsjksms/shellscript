#!/usr/bin/env bash
# Wiki: https://docs.ginuerzh.xyz/gost/
# Usage: bash <(curl -s https://raw.githubusercontent.com/myxuchangbin/shellscript/master/gost/gost.sh)
# Uninstall: systemctl stop gost; systemctl disable gost; rm -rf /etc/systemd/system/gost.service /opt/gost

URL="$(wget -qO- https://api.github.com/repos/ginuerzh/gost/releases/latest | grep -E "browser_download_url.*gost-linux-amd64" | cut -f4 -d\")"
[ -e /opt/gost/ ] || mkdir -p /opt/gost/
[ -e /opt/gost/config.json ] || wget https://raw.githubusercontent.com/myxuchangbin/shellscript/master/gost/config.json -O /opt/gost/config.json
[ -e /opt/gost/gost ] && rm -rf /opt/gost/gost
wget -O - $URL | gzip -d > /opt/gost/gost && chmod +x /opt/gost/gost

cat <<EOF > /etc/systemd/system/gost.service
[Unit]
Description=Gost server
After=syslog.target
After=network.target
[Service]
LimitCORE=infinity
LimitNOFILE=512000
LimitNPROC=512000
Type=simple
StandardOutput=null
#StandardError=journal
WorkingDirectory=/root/gost
ExecStart=/opt/gost/gost -C /opt/gost/config.json
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s TERM $MAINPID
Restart=always
User=root
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable gost.service
systemctl restart gost.service
