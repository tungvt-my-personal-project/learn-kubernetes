
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

cat << EOF >> /etc/hosts
192.168.0.1 vmhost
192.168.0.2 alma-ansiblemaster
192.168.0.3 alma-kubemaster
192.168.0.4 alma-kubeworker1
192.168.0.5 alma-kubeworker2
EOF

if [[ $rc -eq 0 ]] ; then

echo 'proxy=http://10.61.11.42:3128' | tee -a /etc/yum.conf

# export no_proxy=localhost,127.0.0.1,alma-ansiblemaster,alma-kubemaster,alma-kubeworker1,vmhost,192.168.0.1,192.168.0.2,192.168.0.3,192.168.0.4
cat << EOF >> /home/vagrant/.bashrc
export http_proxy=http://10.61.11.42:3128
export https_proxy=http://10.61.11.42:3128
export no_proxy=localhost,127.0.0.1,alma-ansiblemaster,alma-kubemaster,alma-kubeworker1,alma-kubeworker2,vmhost,192.168.0.1,192.168.0.2,192.168.0.3,192.168.0.4,192.168.0.5
EOF
fi