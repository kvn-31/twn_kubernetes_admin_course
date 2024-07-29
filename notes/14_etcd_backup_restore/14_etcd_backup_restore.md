# ETCD - Backup and Restore
- cluster data is stored in etcd
- if etcd is lost, the cluster is lost
- -> backup and restore is crucial

## What etcd stores
- all K8s components have configurations and state
- the application data is NOT stored in etcd (it is stored in cluster/remote storage)

## Backup
- see [documentation](https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/#backing-up-an-etcd-cluster)
- etcdctl is the CLI tool to interact with etcd
- install using `apt install etcd-client`
- authentication is done using ... certificates
- kube api server authenticates with etcd using a client certificate, can be checked `sudo cat /etc/kubernetes/manifests/kube-apiserver.yaml` -> `etcd-cafile`, `etcd-certfile`, `etcd-keyfile` or `sudo cat /etc/kubernetes/manifests/etcd.yaml | grep /etc/kubernetes/pki`
- `sudo ETCDCTL_API=3 etcdctl snapshot save /tmp/etcd-backup.db --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert /etc/kubernetes/pki/etcd/server.crt --key /etc/kubernetes/pki/etcd/server.key` 
  - to backup using a specified API version (check with `etcdctl version`)
  - specifying the certificates
- check the status to check if it has actual data in it
- `sudo ETCDCTL_API=3 etcdctl snapshot status /tmp/etcd-backup.db --write-out=table` 
- this file now needs to be stored in a safe place, encrypted

## Manage etcd independent of K8s cluster
- in our current setup etcd data is stored in `/var/lib/etcd`
- different options to break dependency
  - use remote storage outside the cluster
  - run etcd outside K8s cluster

## Restore
- `sudo -i` switch to root user (to avoid typing sudo all the time)
- `ETCDCTL_API=3 etcdctl snapshot restore /tmp/etcd-backup.db --data-dir /var/lib/etcd-backup` create restore point from backup
- `vim /etc/kubernetes/manifests/etcd.yaml` change the data directory to the backup directory
  - `hostPath` -> `path: /var/lib/etcd-backup`
- kubelet should automatically restart the etcd pod after saving (takes a few seconds) (if not, restart kubelet)
