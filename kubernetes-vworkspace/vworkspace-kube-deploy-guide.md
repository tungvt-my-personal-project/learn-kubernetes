# Hướng dẫn sử dụng Kuberntes để triển khai vworkspace (chưa phù hợp lắm cho production)

## Triển khai vworkspace
Từ project root, cd vào thư mục **kubernetes-vworkspace** Chạy các câu lệnh:
- Tạo ingress, storage class
  ```sh
  kubectl apply -f pre-provision/
  ```
- Tạo redis
  ```sh
  kubectl apply -f vworkspace-redis/
  ```
- Tạo database deployment
  ```sh
  kubectl apply -f vworkspace-db/
  ```
- Tạo nextcloud deployment
  ```sh
  kubectl apply -f vworkspace-app/
  ```

Chú ý: Vì hiện tại ta chưa có vworkspace image nên ta sử dụng image nextcloud thay thế. Ta cần chỉ định image vworkspace trong file [vworkspace-app.yml](./vworkspace-app/vworkspace-app.yml) tại dòng **41**


## Test trang web nextcloud
Thêm dòng sau vào /etc/hosts(trên linux) hoặc C:\Windows\System32\drivers\​etc\hosts (trên window): 
```txt
<kubernetes-node-ip>(vd: 192.168.0.35)  vworkspace.test
<kubernetes-node-ip>(vd: 192.168.0.35)  www.vworkspace.test
```

Ta có thể sử dụng trình duyệt để truy cập vworkspace trên http://vworkspace.test
