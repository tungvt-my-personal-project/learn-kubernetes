gluster peer probe alma-kubemaster
gluster peer probe alma-kubeworker1
gluster peer probe alma-kubeworker2

sleep 30s

gluster volume create gv0 replica 3 alma-kubemaster:/data/brick1/gv0 alma-kubeworker1:/data/brick1/gv0 alma-kubeworker2:/data/brick1/gv0 force
gluster volume start gv0