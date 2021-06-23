# Hướng dẫn sử dụng Kuberntes để triển khai vworkspace (chưa phù hợp lắm cho production)

## 1. Cấu hình gluster volume
- Tạo thư mục /mnt/vworkspace trên tất cả các kubernetes worker node
- Mount gluster volume trên thư mục trên /mnt/vworkspace dùng `sudo mount -f glusterfs /mnt/vworkspace <glusterserver>:/<volumename>` (xem cách tạo gluster volume tại [đây](https://docs.gluster.org/en/latest/Quick-Start-Guide/Quickstart/)) 
- Sau khi mount, tạo các thư mục:
  + /mnt/vworkspace/db
  + /mnt/vworkspace/theme
  + /mnt/vworkspace/data
  + /mnt/vworkspace/custom_apps
  + /mnt/vworkspace/config

## 2. Triển khai vworkspace (nextcloud?) trên kubernetes
- Chạy câu lệnh `kubectl apply -f <path>/kubernetes-vworkspace` trên control plane node
- Chờ kuberntes tạo các container cần thiết. Bây giờ ta có thể truy cập vào port *30008* trên tất cả worker node. Ta có thể dùng 1 load balancer bên ngoài như HA Proxy để loadbalance các node này.
- Chú ý: Vì hiện tại ta chưa có vworkspace image nên ta sử dụng image nextcloud thay thế. Ta cần chỉ định image vworkspace trong file **vworkspace-app.yml** tại dòng **41**
