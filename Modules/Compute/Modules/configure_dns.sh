#!/bin/bash
sudo apt update

sudo systemctl enable systemd-resolved
sudo systemctl start systemd-resolved

cat <<EOF > /etc/netplan/50-cloud-init.yaml
network:
version: 2
ethernets:
    eth0:
    dhcp4: true
    nameservers:
        addresses: [168.63.129.16]

EOF

sudo netplan apply

sudo systemctl restart systemd-resolved