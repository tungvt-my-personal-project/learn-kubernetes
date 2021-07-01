# Hướng dẫn triển khai glusterfs cho storage và cấu hình gluster

## 1.Yêu cầu glusterfs
- Cần có 3 node trở lên và số node là một số lẻ là tốt nhất
- Kết nối giữa các node và từ các node tới kubernetes cluster
- Mỗi node có một ổ cứng dành riêng cho glusterfs (không chứa hệ điều hành, chưa có phân vùng, chưa có filesystem)

## 2. Cài đặt glusterfs
- Cài đặt gluster theo hướng dẫn như documentation trên gluster docs. 
- Chú ý: chỉ cần cài đặt service gluster trên các node và tạo cluster bằng ```peer probe``` thành công. chưa format ổ cứng hoặc tạo volume

## 3. Cấu hình dynamic glusterfs provisioning
Để có thể quản lý glusterfs cho dynamic provisioning, ta cần triển khai [heketi server](https://github.com/heketi/heketi)

Ta có 2 cách triển khai heketi
- Triển khai heketi container trên kubernetes
- Cài đặt heketi trên node riêng

Hướng dẫn này sẽ hướng dẫn cách triển khai heketi container trên kubernetes
### A. Cấu hình ssh key
- Generate ssh key
  ```sh
  ssh-keygen -t rsa -b 4069 -m pem
  ```
  heketi không nhận ssh-key được tạo mà không có flag ```-m pem```
- Cấu hình ssh-key pair cho phép login tài khoản root trên các node của glusterfs dùng ssh key.
- vd ssh key:
  - [private key](./kubernetes/heketikey)
  - [public key](./kubernetes/heketikey.pub)

### B. Triển khai heketi
#### Trên glusterfs node
Tạo heketi share folder trên cả 3 node
```sh
sudo mkdir -p /mnt/heketi
```
Tạo và start gluster shared volume có tên **heketi** trên root disk (chứa os) hoặc một ổ đĩa không dành cho kubernetes
```sh
gluster volume create heketi replica 3 node1:/mnt/heketi node2:/mnt/heketi node3:/mnt/heketi
gluster volume start heketi
```

#### Trên kubernetes control node
Tạo namespace *gluster-dynamic* sử dụng file [heketi-namespace.yml](./heketi-namespace.yml)
```sh
kubectl apply -f heketi-namespace.yml 
```
Tạo ssh secret sử dụng private ssh key cho heketi (vd với file [heketikey](./kubernetes/heketikey))
```sh
kubectl create secret generic heketi-ssh-secret  --from-file=./heketikey
```
Tạo gluster endpoint dùng file [gluster-endpoint.yml](./kubernetes/gluster-endpoint.yml), sửa lại ip addresses trong phần **subsets** cho phù hợp
```sh
kubectl apply -f gluster-endpoint.yml
```

Triển khai heketi-deployment với file [heketi-deployment](./kubernetes/heketi-deployment.yml)
```sh
kubectl apply -f heketi-deployment.yml
```
Theo dõi kubernetes tạo pod cho heketi. Sau khi tạo xong, heketi sẽ nghe trên port 30001 của tất cả các node
```sh
kubectl -n=gluster-dynamic get pods --watch
```


### C. Xác nhận cài đặt heketi và cấu hình gluster
Trên control node hoặc máy của bạn cài đặt heketi-cli
```sh
HEKETI_BIN="heketi-cli"      # heketi or heketi-cli
HEKETI_VERSION="9.0.0"       # latest heketi version => https://github.com/heketi/heketi/releases
HEKETI_OS="linux"            # linux or darwin

curl -SL https://github.com/heketi/heketi/releases/download/v${HEKETI_VERSION}/heketi-v${HEKETI_VERSION}.${HEKETI_OS}.amd64.tar.gz -o /tmp/heketi-v${HEKETI_VERSION}.${HEKETI_OS}.amd64.tar.gz && \
tar xzvf /tmp/heketi-v${HEKETI_VERSION}.${HEKETI_OS}.amd64.tar.gz -C /tmp && \
rm -vf /tmp/heketi-v${HEKETI_VERSION}.${HEKETI_OS}.amd64.tar.gz && \
cp /tmp/heketi/${HEKETI_BIN} /usr/local/bin/${HEKETI_BIN}_${HEKETI_VERSION} && \
rm -vrf /tmp/heketi && \
cd /usr/local/bin && \
ln -vsnf ${HEKETI_BIN}_${HEKETI_VERSION} ${HEKETI_BIN} && cd

unset HEKETI_BIN HEKETI_VERSION HEKETI_OS
```

Load [heketi-topology.json](./kubernetes/heketi-topology.json) vào heketi. Chú ý cần sửa lại file này cho phù hợp với địa chỉ ip của gluster cluster. Xem cách cấu hình tại [đây](https://github.com/heketi/heketi/blob/master/docs/admin/topology.md)
```sh
heketi-cli --user admin --secret <mật khẩu> --server http://localhost:3000 topology load --json heketi-topology.json
```

Kiểm tra heketi đã nhận gluster cluster
```sh
heketi-cli --user admin --secret <mật khẩu> --server http://localhost:3000 cluster list
```
