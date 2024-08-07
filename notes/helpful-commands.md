## Kubectl
- quick hack to avoid writing `kubectl` the whole time: `alias k=kubectl` (only for active session, not permanent)
- to create a declarative file out of an imperative `kubectl create x` command: `kubectl create x --dry-run=client -o yaml > file.yaml` 
  - exports the whole preview to a yaml file, which can then be edited and applied
  - some fields might need to be deleted such as `status` or `creationTimestamp`
  - quick hack for vim is to use `dd` to delete a line
- `kubectl cluster-info` for ip addresses of control plane and CoreDns 

### APPLY
- `kubectl apply -f <file>` - Apply a configuration file
- `kubectl apply -f <directory>` - Apply all configuration files in a directory (use `.` for current directory)

### GET
- `kubectl get pods` - List all pods in the current namespace
- `kubectl get pods -n kube-system` - List all pods in the kube-system namespace
- `kubectl get pods --all-namespaces` - List all pods in all namespaces
- `kubectl get pods -o wide` - List all pods with more information
- `kubectl get ep` - List all endpoints (IP addresses of pods that a service is routing traffic to)
- `kubectl get all` - List all resources
- `kubectl get svc -o yaml` - Get the service in yaml format -> shows auto generated fields
- `kubectl get <component type> --show-labels` - List all components with the labels
- `kubectl get <component type> -l <label>` - List all components with a specific label
- `kubectl get pod -o jsonpath="{range .items[*]}{.metadata.name}{.spec.containers[*].resources}{'\n'}"` - Get the resources of the pods

### DELETE
- `kubectl delete <component type> <name>` - Delete a component
- `for p in $(kubectl get pods | grep Terminating | awk '{print $1}'); do kubectl delete pod $p --grace-period=0 --force;done` - Delete all pods that are in the Terminating state

### DESCRIBE
- `kubectl describe <component type> <name>` detailed information about a component

### EDIT
- `kubectl edit <component type> <name>` - Edit a component -> also shows auto generated fields

### LOGS
- `kubectl logs <pod name>` - Get the logs of a pod
- `kubectl logs -l <label>` - Get the logs of all pods with a specific label
- `kubectl logs PODNAME -c log-sidecar` - Get the logs of a specific container in a pod

### EXEC
- `kubectl exec -it <pod name> -- bash` - Execute a command in a pod

### CONFIG
- `kubectl config get-contexts` -> shows all contexts
- `kubectl config current-context` -> shows the current context
- `kubectl config use-context <context-name>` -> sets the current context
- `kubectl config set-context --current --namespace=kube-system` -> sets the namespace for the current context to kube-system

### SCALE
- `kubectl scale deployment <deployment-name> --replicas=<number>` instead of applying an adapted deployment file

### REPLICASET
- `kubectl get rs` - List all ReplicaSets

### EXPOSE
- `kubectl expose deployment nginx-deployment --type=NodePort --name=nginx-service` - Expose a deployment as a nodeport service

### ROLLOUT
- `kubectl rollout history <component type> <component-name>` - Show the history of a deployment, daemonset, or statefulset
- `kubectl rollout undo deployment NAME` -> roll back to the previous version
- `kubectl rollout undo deployment NAME --to-revision=2` -> roll back to a specific revision
- `kubectl rollout status deployment NAME` -> shows the status of the rollout

### LABEL
- `kubectl label <component type> <component-name> <label-key>=<label-value>` - Add a label to a component

### AUTH
- `kubectl auth can-i get pods --as <user>` - Check if a user can get pods

### CSR / certificate
- `kubectl get csr` to see all CSR with their states
- `kubectl certificate approve dev-tom` approve a certificate with name dev-tom
- `kubectl get csr dev-tom -o yaml` print out the signed certificate in yaml format

### Flags (that can be used for most commands)
- `kubectl options` print all options that are available globally
- `--show-labels` - Show labels
- `--record` - Add a record to the deployment history (deprecated)

## Cilium
- `kubectl get pods -A | grep cilium` - List all pods with cilium in the name
- `kubectl -n kube-system exec -it cilium-xxxxx -- cilium-dbg status` - Get the status of Cilium
- `cilium connectivity test` - Test connectivity (can take up to 15 mins)

## Helm
- `helm ls` - List all helm releases
- `helm install <release-name> <chart-name>` - Install a helm chart
- `helm uninstall <release-name>` - Uninstall a helm release

## ETCDL
- install etcdctl: `apt install etcd-client`
- `sudo ETCDCTL_API=3 etcdctl snapshot save /tmp/etcd-backup.db --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert /etc/kubernetes/pki/etcd/server.crt --key /etc/kubernetes/pki/etcd/server.key`
  - to backup using a specified API version (check with `etcdctl version`)
  - specifying the certificates
- `sudo ETCDCTL_API=3 etcdctl snapshot status /tmp/etcd-backup.db --write-out=table`  check the status of the backup to check if it has actual data in it

## Kubeadm
- `sudo kubeadm certs check-expiration` -> checks the expiration of the certificates
