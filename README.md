# Cài đặt và cấu hình kubernetes cho VWorkspace

## 1. Hướng dẫn Tạo kubernetes cluster trên local cho mục đích dev
Xem [hướng dẫn](vagrant-script/vagrant-guide.md) tạo một kubernetes cluster cơ bản

## 2. Cài đặt và cấu hình glusterfs cho dynamic provisioning
- [Hướng dẫn](heketi-dynamic-config/heketi-deploy-guide.md)

## 3. Hướng dẫn cài đặt nginx ingress
Nếu không có helm, ta cần cài đặt theo hướng dẫn tại [đây](https://helm.sh/docs/intro/install/)

Cài đặt nginx ingress sử dụng helm
```sh
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm install ingress-nginx ingress-nginx/helm install ingress-nginx ingress-nginx/ingress-nginx --set controller.hostNetwork=true,controller.service.type="",controller.kind=DaemonSet -n ingress-nginx --create-namespace
```

## 4. Hướng dẫn tạo triển khai vwworkspace cơ bản trên kubernetes
- [Hướng dẫn](kubernetes-vworkspace/vworkspace-kube-deploy-guide.md)
