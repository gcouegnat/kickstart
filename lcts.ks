# LCTS kickstart file for CentOS-6.5
# Guillaume Couegnat <couegnat@lcts.u-bordeaux1.fr>
# Last modified: 2014-05-14
install
text
nfs --server=192.0.1.108 --dir=/share/iso

lang en_US.UTF-8
keyboard fr
timezone --utc Europe/Paris

rootpw --iscrypted $1$4V445ma2$DJ13GjnxoxAoyzlQzHRmm/
authconfig --enableshadow --passalgo=sha512

network --bootproto=dhcp --device=eth0 --onboot=on
firewall --disabled
selinux  --disabled

bootloader --location=mbr --append="rhgb quiet"
zerombr

clearpart  --all
part /boot --fstype=ext4 --ondisk=sda  --size=100
part pv.01 --size=1 --grow --ondisk=sda
volgroup vg0 pv.01
logvol /        --vgname=vg0 --size=10240     --name=root    --fstype=ext4
logvol /scratch --vgname=vg0 --size=1 --grow  --name=scratch --fstype=ext4
logvol swap     --vgname=vg0 --recommended    --name=swap    --fstype=swap

xconfig --startxonboot
firstboot --disable
logging --level=info
reboot --eject

repo --name=epel --baseurl=http://mirrors.ircam.fr/pub/fedora/epel/6/x86_64/

%packages
@base
@core
@basic-desktop
@desktop-platform
@development
@directory-client
@emacs
@french-support
@internet-browser
@legacy-x
@legacy-x-base
@network-file-system-client
@office-suite
@x11
ImageMagick
dejavu-*
evince
gedit
gedit-plugins
gimp
gnuplot
kernel-devel
kernel-headers
libXmu
libXp
liberation-*
lm_sensors
nautilus-open-terminal
gnome-system-monitor
openmotif
smartmontools
tree
vim-X11
epel-release
%end

%post --log=/root/ks-post.log
set -x -v

# autofs config
cat > /etc/auto.master << EOF
/autofs /etc/auto.nfs   --timeout=3 --ghost
EOF
cat > /etc/auto.nfs << EOF
users   -nfsvers=3,tcp  192.0.1.108:/home
share   -nfsvers=3,tcp  192.0.1.108:/share
data    -nfsvers=3,tcp  192.0.1.21:/data0
EOF

# Create /opt/hpc in /etc/fstab
mkdir -pv /opt/hpc
cat >> /etc/fstab << EOF
192.0.1.108:/opt/hpc /opt/hpc nfs defaults 0 0
EOF

chkconfig nfs    on
chkconfig autofs on

# Copy root public key
mkdir -pv /root/.ssh && chmod 700 /root/.ssh
touch /root/.ssh/authorized_keys && chmod 600 /root/.ssh/authorized_keys
cat >> /root/.ssh/authorized_keys << EOF
ssh-dss AAAAB3NzaC1kc3MAAACBANfP5z/bptXzzdL0mPBWRt8pgVnUtm9uTDGWrUX034RX9JrirrAjBL7bWFyhTPEBzw1JMv4vGf/dwNCsyDJM4wDIryz+tBXvnuPMYGApOXPxeBHw7TcbogS0ttedfyg5yUAAdrg4qvd9O9fA8QXBe/fdTn48zj+5COiCSKmUcSm9AAAAFQDeYnMK1zDda4xxgX/Qp4Cg8YVBpQAAAIAqkdsx/WM6gJSAgXyAhiJxwsRsjwfRGrHQxgFaMKRD0kdNSkplDA7+tMpnPN40FYSJWy0pDGfXiNegZLEP3NtTeL/PVFoq4cJC2Uk4xguhpDO4AlJWNX5ee48wXTIf+yezuEaQfP8hDTph9CJdxWJmPkBPYgm5qNakZgPzhtuh4gAAAIEArspqYiYvOwwWOwHYbkf1a0nErkgjpmo0xTHlOc5K2oTqrcRh0yoQGfLhOyAp138ZmWT7w/rnQqIRopdQsdoiizUUReAqYg7+fB5ihv47NzxUm8WecIazfOHnUveSxM0C/MDnz9rBXxY1pb31dzd70y/+qT+ATsuRzI8al1SKLtE= root@clutomaster
EOF

# Synchronize date and time with master node
/usr/sbin/ntpdate -u clutomaster.lcts.fr
/usr/sbin/hwclock -w

# Install extra packages from EPEL
yum install --enablerepo=epel -y htop

exit 0
%end

