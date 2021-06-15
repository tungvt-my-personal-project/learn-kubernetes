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
  export http_proxy=http://10.61.11.42:3128
  export https_proxy=http://10.61.11.42:3128
  export no_proxy=localhost,127.0.0.1,alma-ansiblemaster,alma-kubemaster,alma-kubeworker1,vmhost,192.168.0.1,192.168.0.2,192.168.0.3,192.168.0.4
fi

#set kubeadm version
VERSION=1.21
OS=CentOS_8

#set pod network CIDR
POD_NETWORK_CIDR=10.217.0.0/16

#config iptables for bridge network
cat <<EOF | tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system

#disable swap for kubeadm
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

#install CRI-O
# Create the .conf file to load the modules at bootup
cat <<EOF | tee /etc/modules-load.d/crio.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

# Set up required sysctl params, these persist across reboots.
cat <<EOF | tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sysctl --system

if [ -z ${http_proxy} ] ; then
curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable.repo https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/devel:kubic:libcontainers:stable.repo --proxy $http_proxy
curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable:cri-o:$VERSION.repo https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:$VERSION/$OS/devel:kubic:libcontainers:stable:cri-o:$VERSION.repo --proxy $http_proxy
else 
curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable.repo https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/devel:kubic:libcontainers:stable.repo
curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable:cri-o:$VERSION.repo https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:$VERSION/$OS/devel:kubic:libcontainers:stable:cri-o:$VERSION.repo
fi

yum update -y
yum install cri-o -y

#config cgroup for crio
# cat <<EOF | sudo tee /etc/crio/crio.conf.d/02-cgroup-manager.conf
# [crio.runtime]
# conmon_cgroup = "pod"
# cgroup_manager = "cgroupfs"
# EOF

systemctl daemon-reload
systemctl enable crio --now

#runc of official repo have serious bug so we have to build and install latest runc version
#uninstall runc
sudo dnf remove runc

#install runc build tool
dnf install libseccomp-devel -y
dnf install wget -y
dnf groupinstall "Development Tools" -y
dnf install git -y

#install golang
cd ~
wget https://golang.org/dl/go1.15.5.linux-amd64.tar.gz
tar -zxvf go1.15.5.linux-amd64.tar.gz -C /usr/local/
export PATH=$PATH:/usr/local/go/bin

# build and install runc-v1.0.0-rc95
wget https://github.com/opencontainers/runc/releases/download/v1.0.0-rc95/runc.tar.xz
tar -xf runc.*
cd runc-*
git init
make
make install
alternatives --install /usr/sbin/runc runc /usr/local/sbin/runc 1

#clean up
dnf groupremove "Development Tools" -y
dnf remove git -y
rm -rf /usr/local/go
rm -rf ~/go* ~/runc*

#config crio proxy
if [ -z ${http_proxy} ] ; then
echo "no proxy configured"
else
cat << EOF | tee -a /etc/sysconfig/crio
NO_PROXY="localhost,127.0.0.1,192.168.0.0/27,$POD_NETWORK_CIDR"
HTTP_PROXY="http://10.61.11.42:3128/"
HTTPS_PROXY="http://10.61.11.42:3128/"
EOF
fi

#restart crio because i can
systemctl daemon-reload
systemctl restart crio

#install kubelet
#add kubernetes repo
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF

#change selinux to permissive
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
sudo setenforce 0

#install kubelet kubeadm kubectl
sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

#enable kubelet
sudo systemctl enable --now kubelet

#install helm
cd ~
wget https://get.helm.sh/helm-v3.6.0-linux-amd64.tar.gz
tar -xzvf helm-*
sudo cp ./linux-amd64/helm /usr/local/bin/
rm -rf ~/linux-amd64 ~/helm-*
helm repo add cilium https://helm.cilium.io/

#install cilium cli
curl -L --remote-name-all https://github.com/cilium/cilium-cli/releases/latest/download/cilium-linux-amd64.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-amd64.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-amd64.tar.gz /usr/local/bin
rm cilium-linux-amd64.tar.gz{,.sha256sum}

#init kubeadm
# kubeadm init --pod-network-cidr=10.217.0.0/16 --apiserver-advertise-address=192.168.0.3 -v=5

# mkdir -p $HOME/.kube
# sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
# sudo chown $(id -u):$(id -g) $HOME/.kube/config

#install cilium
# cd ~
# curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
# chmod 700 get_helm.sh
# ./get_helm.sh
# export PATH=$PATH:/usr/local/bin
# helm repo add cilium https://helm.cilium.io/
# helm install cilium cilium/cilium --version 1.10.0 --namespace kube-system

# #install ciliumcli
# curl -L --remote-name-all https://github.com/cilium/cilium-cli/releases/latest/download/cilium-linux-amd64.tar.gz{,.sha256sum}
# sha256sum --check cilium-linux-amd64.tar.gz.sha256sum
# sudo tar xzvfC cilium-linux-amd64.tar.gz /usr/local/bin
# rm cilium-linux-amd64.tar.gz{,.sha256sum}