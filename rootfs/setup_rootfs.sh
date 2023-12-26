#!/bin/sh
#
set -ex

export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true
export LC_ALL=C LANGUAGE=C LANG=C

/var/lib/dpkg/info/base-passwd.preinst install
/var/lib/dpkg/info/sgml-base.preinst install

mkdir -p /etc/sgml
mount proc -t proc /proc
mount -B sys /sys
mount -B run /run
mount -B dev /dev
#mount devpts -t devpts /dev/pts
dpkg --configure -a
# Needed because we get permissions problems for some reason
chmod 0666 /dev/null

unset DEBIAN_FRONTEND DEBCONF_NONINTERACTIVE_SEEN

#
# Change root password to 'debian'
#
usermod --password "$(echo rv | openssl passwd -1 -stdin)" root

#
# Add a new user debian and its passwd is `debian`
#
mkdir -p /home/debian
useradd --password dummy \
    -G cdrom,floppy,sudo,audio,dip,video,plugdev \
    --home-dir /home/debian --shell /bin/bash debian
chown debian:debian /home/debian
# Set password to 'debian'
usermod --password "$(echo debian | openssl passwd -1 -stdin)" debian 

# Set up fstab
cat > /etc/fstab <<EOF
# <file system> <mount point>   <type>  <options>       <dump>  <pass>
/dev/mmcblk1p2 /boot/efi      vfat    umask=0077      0       1
EOF

#apt install -f /tmp/*.deb

mv /tmp/*.deb /boot

# change device tree
echo "===== ln -s dtb files ====="
file_prefix="/usr/lib/linux-image-*"

file_path=$(ls -d $file_prefix)

if [ -e "$file_path" ]; then
  echo "File found: $file_path"
  lib_dir=$file_path
else
  echo "File not found: $file_path"
fi

kernel_image=${lib_dir##*/}


# cp your latest dtb file,e.g, cp /usr/lib/linux-image-xx-riscv64
# need you confirm it here
cat <<EOF >> /etc/default/u-boot
U_BOOT_PARAMETERS="rw console=tty0 console=ttyS0,115200 earlycon rootwait stmmaceth=chain_mode:1 selinux=0"
EOF

cat /boot/extlinux/extlinux.conf

#dpkg-reconfigure ${kernel_image}

# update u-boot
#update-initramfs -c -k all

u-boot-update

# boot from sd card
cat <<EOF >> /boot/scripts.txt
sed -i -e 's|root=[^ ]*|root=/dev/mmcblk1p3|' /boot/extlinux/extlinux.conf
cd ${lib_dir}/starfive/
ln -s jh7110-starfive-visionfive-2-v1.2a.dtb jh7110-visionfive-v2.dtb
cd - 
EOF

# double check
cat /boot/extlinux/extlinux.conf

# create /boot/efi
mkdir -p /boot/efi

# setup uboot uEnv
cat <<EOF > /boot/uEnv.txt
kernel_comp_addr_r=0xb0000000
kernel_comp_size=0x10000000
EOF

# Set hostname
echo vf2 > /etc/hostname

# 
cat >> /etc/hosts << EOF
127.0.0.1      vf2 
EOF

# Add needed modules in initrd
#echo "nvme" >> /etc/initramfs-tools/modules

# 
# Enable system services
#
#systemctl enable systemd-resolved.service

# Update source list 

rm -rf /etc/apt/sources.list.d/multistrap-debian.list

cat > /etc/apt/sources.list <<EOF
deb https://mirror.iscas.ac.cn/debian sid main non-free-firmware
EOF

#
# Clean apt cache on the system
#
apt-get clean

umount /proc
umount /sys
umount /run
umount /dev

# set the time immediately at startup
#sed -i 's/^DAEMON_OPTS="/DAEMON_OPTS="-s /' /etc/default/openntpd

rm -rf /var/cache/*
find /var/lib/apt/lists -type f -not -name '*.gpg' -print0 | xargs -0 rm -f
find /var/log -type f -print0 | xargs -0 truncate --size=0
