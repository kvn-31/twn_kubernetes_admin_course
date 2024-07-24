## Kubectl
- quick hack to avoid writing `kubectl` the whole time: `alias k=kubectl` (only for active session, not permanent)
- to create a declarative file out of an imperative `kubectl create x` command: `kubectl create x --dry-run=client -o yaml > file.yaml` 
  - exports the whole preview to a yaml file, which can then be edited and applied
  - some fields might need to be deleted such as `status` or `creationTimestamp`
  - quick hack for vim is to use `dd` to delete a line
- `kubectl cluster-info` for ip addresses of control plane and CoreDns 

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

### SCALE
- `kubectl scale deployment <deployment-name> --replicas=<number>` instead of applying an adapted deployment file

### ROLLOUT
- `kubectl rollout history <component type> <component-name>` - Show the history of a deployment, daemonset, or statefulset

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
