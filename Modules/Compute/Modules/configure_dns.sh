#!/bin/bash

sudo apt update
sudo systemctl stop systemd-resolved
sudo systemctl disable systemd-resolved

sudo apt install -y dnsmasq

cat <<EOF > /etc/dnsmasq.conf
    server=/privatelink.file.core.windows.net/168.63.129.16
    server=/nicholas.internal/168.63.129.16
    server=8.8.8.8
    server=1.1.1.1
    listen-address=127.0.0.1
    listen-address=10.0.4.4
EOF

sudo systemctl restart dnsmasq
sudo systemctl enable dnsmasq