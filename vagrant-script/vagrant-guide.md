# Hướng dẫn sử dụng vagrant để tạo kubernetes cluster trên VirtualBox

## 1. Yêu cầu
- Cài đặt [Oracle VirtualBox](https://www.virtualbox.org/)
- Cài đặt [Vagrant](https://www.vagrantup.com/downloads)
- Đủ tài nguyên máy tính (mỗi máy ảo sẽ có 4 vcpus và 4gb RAM)

Chú ý: nếu có proxy ta cần thêm các biến môi trường HTTP_PROXY, HTTPS_PROXY, NO_PROXY tương ứng

## 2. Sử dụng vagrant tạo các node kubernetes
- Nếu proxy không phải là http://10.61.11.42:3128, ta cần sửa lại các dòng sau trong các script:
  + [config-proxy.sh](./config-proxy.sh): 4, 23, 27, 28, 29
  + [install-gluster.sh](./install-gluster.sh): 3, 13
  + [install-kubeadm.sh](./install-kubeadm.sh): 3. 13. 14. 15
- Mở powershell, ```cd``` vào thư mục này
- Chạy vagrant up
- Chờ vagrant provision các vm trên virtualbox. 3 máy ảo sẽ được tạo: alma-kubemaster, alma-kubeworker1, alma-kubeworker2. Ta giờ có thể SSH vào các này bằng cách đánh `vagrant ssh <tên máy>`.

## 3. Setup kubernetes cluster
- Trên control plane (alma-kubemaster)
  + SSH vào alma-kubemaster
  + Tạo control plane: `kubeadm init --pod-network-cidr=10.217.0.0/16 --apiserver-advertise-address=192.168.0.3 -v=5`. Chú ý: "pod-network-cidr" không được trùng với bất kì network nào cluster có thể kết nối đến
  + Cho phép kubectl truy cập vào control plane (ko chạy trên root user):
  ```sh
  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config
  ``` 
  + Cài Cilium CNI: `helm install cilium cilium/cilium --version 1.10.0 --namespace kube-system`.
  + Giờ ta có thể quản lý
  + Chú ý: sau khi cài Cilium. ta không thể dùng `vagrant ssh` để SSH vào các máy này. Ta có thể lấy ssh-config bằng cách chạy `vagrant ssh-config` và dùng config này ssh vào các máy này tại *192.168.0.3*, *192.168.0.4*, *192.168.0.5*
- Trên worker nodes
  + Chạy `kubeadm token create -ttl=1h --print-join-command` trên control plane và lấy câu lệnh in ra chajy trên các worker nodes để join các worker node trên cluster