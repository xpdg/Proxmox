#!/usr/bin/env bash

# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/tteck/Proxmox/raw/main/LICENSE

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y curl
$STD apt-get install -y sudo
$STD apt-get install -y mc
$STD apt-get install -y sqlite3
msg_ok "Installed Dependencies"

msg_info "Setting up ARR User/Group"
$STD groupadd -g 6553 Servarr
$STD useradd -u 5403 -g 6553 -s /sbin/nologin -M prowlarr
msg_ok "Finished setting up ARR User/Group"

msg_info "Installing Prowlarr"
mkdir -p /var/lib/prowlarr/
chmod 775 /var/lib/prowlarr/
$STD wget --content-disposition 'https://prowlarr.servarr.com/v1/update/master/updatefile?os=linux&runtime=netcore&arch=x64'
$STD tar -xvzf Prowlarr.master.*.tar.gz
mv Prowlarr /opt
chmod 775 /opt/Prowlarr
chown prowlarr:Servarr /var/lib/prowlarr/
chown prowlarr:Servarr /opt/Prowlarr
msg_ok "Installed Prowlarr"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/prowlarr.service
[Unit]
Description=Prowlarr Daemon
After=syslog.target network.target
[Service]
User=prowlarr
Group=Servarr
UMask=0002
Type=simple
ExecStart=/opt/Prowlarr/Prowlarr -nobrowser -data=/var/lib/prowlarr/
TimeoutStopSec=20
KillMode=process
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF
systemctl -q daemon-reload
systemctl enable --now -q prowlarr
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf Prowlarr.master.*.tar.gz
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
