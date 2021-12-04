

echo "SelfServer" > /etc/hostname
cat > /etc/hosts << EOF
127.0.0.1 localhost
127.0.1.1 $(cat /etc/hostname)
EOF

DEBIAN_FRONTEND=noninteractive apt-get update 
DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends linux-image-amd64 live-boot systemd-sysv -y 
DEBIAN_FRONTEND=noninteractive apt-get install sudo network-manager snapraid parted gdisk mergerfs -y 
DEBIAN_FRONTEND=noninteractive apt-get install wget unclutter xorg chromium openbox lightdm locales -y 

useradd -G sudo -m -p SelfServer administrator 

systemctl enable network-manager

mkdir -p /home/administrator/.config/openbox 
mkdir -p /mnt/data 
mkdir -p /mnt/parity 
echo "
# SnapRAID Data Disks

# SnapRAID Parity Disks

# MergerFS Pool
/mnt/data/* /storage fuse.mergerfs allow_other,direct_io,use_ino,category.create=lfs,moveonenospc=true,minfreespace=20G,fsname=mergerfsPool 0 0

" >> /etc/fstab 

chmod +x /usr/sbin/selfserver  
cat > /etc/systemd/system/selfserver.service << EOF
[Unit]
Description=SelfServer

Wants=network.target
After=multi-user.target syslog.target network-online.target

[Service]
Type=simple
ExecStart=/usr/sbin/selfserver
Restart=on-failure
RestartSec=10
KillMode=process

[Install]
WantedBy=multi-user.target

EOF
chmod 640 /etc/systemd/system/selfserver.service
systemctl enable selfserver
cat > /etc/X11/xorg.conf.d/15-no-vt.conf << EOF
Section "ServerFlags"
    Option "DontVTSwitch" "true"
EndSection
EOF
sed -i.bak '/^\[Seat:\*\]$/a autologin-user=administrator\nautologin-user-timeout=0' /etc/lightdm/lightdm.conf
cat > /home/administrator/.config/openbox/autostart << EOF
#!/bin/bash
unclutter -idle 0.1 -grab -root &
while :
do
  chromium \
    --no-first-run \
    --start-maximized \
    --window-position=0,0 \
    --window-size=1024,768 \
    --disable \
    --disable-translate \
    --disable-infobars \
    --disable-suggestions-service \
    --disable-save-password-bubble \
    --disable-session-crashed-bubble \
    --incognito \
    --kiosk "http://localhost:8080/"
  sleep 5
done &
EOF
chown -R administrator:administrator /home/administrator/.config


apt-get install dropbear-run -y 
sudo systemctl enable dropbear
sed -i 's,^NO_START=1,NO_START=0,' /etc/default/dropbear

apt-get autoremove
apt-get clean
exit
