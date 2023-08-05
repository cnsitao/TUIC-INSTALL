#!/bin/bash

clear
echo "Hello! 欢迎使用TUIC脚本"
echo "作者:https://t.me/iu536"

read -p "请输入你的域名:" domain

read -p "输入节点端口[默认10010]:" port
            if [ -z $port ]
                then port=10010
            fi

read -p "请输入密码[默认cheatgfw233]:" password
if [ -z $password ]
                then password=cheatgfw233
            fi

mkdir /tuic
wget https://github.com/EAimTY/tuic/releases/download/tuic-server-1.0.0/tuic-server-1.0.0-x86_64-unknown-linux-gnu
mv tuic-server-1.0.0-x86_64-unknown-linux-gnu  /tuic/tuic-server
cp /tuic/tuic-server /usr/local/bin/tuic
chmod +x  /usr/local/bin/tuic
apt update
apt install socat -y
curl https://get.acme.sh | sh
ln -s  /root/.acme.sh/acme.sh /usr/local/bin/acme.sh
source ~/.bashrc
acme.sh --set-default-ca --server letsencrypt
acme.sh --issue -d $domain --standalone -k ec-256 --force
acme.sh --installcert -d $domain --ecc  --key-file  /tuic/private.key   --fullchain-file /tuic/cert.crt

cat << EOF > /etc/systemd/system/tuic.service
[Unit]
Description=tuic service
Documentation=https://github.com/EAimTY/tuic
After=network.target nss-lookup.target

[Service]
User=root
WorkingDirectory=/tuic/
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
ExecStart=/usr/local/bin/tuic -c /tuic/config.json
Restart=on-failure
RestartSec=10
LimitNOFILE=infinity

[Install]
WantedBy=multi-user.target
EOF

uuid=`cat /proc/sys/kernel/random/uuid`

cat << EOF > /tuic/config.json
{
    "server": "[::]:10010",
    "users": {
        "$uuid": "$password"    },
    "certificate": "/tuic/cert.crt",
    "private_key": "/tuic/private.key",
    "alpn": ["h3"],
    "congestion_control": "bbr",
    "log_level": "info"
}
EOF
systemctl enable tuic.service
systemctl start tuic.service

ip=`curl ip.sb -4`
cat << EOF >/tuic/node
{
    "relay": {
        "server": "$domain:$port", 
        "uuid": "$uuid", 
        "password": "$password", 
        "ip": "$ip",
        "udp_relay_mode": "quic",
        "congestion_control": "bbr",
	"alpn": ["h3"]
    },
    "local": {
        "server": "127.0.0.1:18080",
        "dual_stack": true,
        "max_packet_size": 1500
    },
    "log_level": "info"
}
EOF

echo "安装完成！"
echo "v2rayN配置文件："
cat /tuic/node
