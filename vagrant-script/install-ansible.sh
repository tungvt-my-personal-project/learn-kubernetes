sudo dnf update -y
sudo dnf install wget -y
sudo dnf install python39 -y
sudo dnf install git -y
pip3 install --user wheel
pip3 install --user ansible
pip3 install --user paramiko

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
  git config --global http.https://github.com.proxy http://10.61.11.42:3128
fi

