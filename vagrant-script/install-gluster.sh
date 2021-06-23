((count = 10))
while [[ $count -ne 0 ]] ; do
    ping -c 1 10.61.11.42
    rc=$?
    if [[ $rc -eq 0 ]] ; then
        ((count = 0))
    else
    ((count = count - 1))
    fi
done

if [[ $rc -eq 0 ]] ; then
  curl https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official -o /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official --proxy http://10.61.11.42:3128
else
  curl https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official -o /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official
fi

rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official

cat << 'EOF' | sudo tee /etc/yum.repos.d/CentOS-Linux-Extras.repo
# CentOS-Linux-Extras.repo
#
# The mirrorlist system uses the connecting IP address of the client and the
# update status of each mirror to pick current mirrors that are geographically
# close to the client.  You should use this for CentOS updates unless you are
# manually picking other mirrors.
#
# If the mirrorlist does not work for you, you can try the commented out
# baseurl line instead.

[centos-extras]
name=CentOS Linux $releasever - Extras
mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=extras&infra=$infra
#baseurl=http://mirror.centos.org/$contentdir/$releasever/extras/$basearch/os/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official
EOF

dnf --enablerepo='centos-extras' update -y
dnf --enablerepo='centos-extras' install gdisk net-tools centos-release-gluster wget -y
dnf update -y
dnf install --enablerepo='centos-extras' glusterfs-server -y
systemctl enable glusterd --now

sgdisk -a=2048 -N=1 /dev/sdb
mkdir -p /data/brick1
echo '/dev/sdb1 /data/brick1  xfs defaults  0 0' | sudo tee -a /etc/fstab
mkfs -t xfs -i size=512 /dev/sdb1
mount -a
mkdir /data/brick1/gv0