## Kubectl
- `kubectl get pods` - List all pods in the current namespace
- `kubectl get pods -n kube-system` - List all pods in the kube-system namespace
- `kubectl get pods --all-namespaces` - List all pods in all namespaces
- `kubectl get pods -o wide` - List all pods with more information


## Cilium
- `kubectl get pods -A | grep cilium` - List all pods with cilium in the name
- `kubectl -n kube-system exec -it cilium-xxxxx -- cilium-dbg status` - Get the status of Cilium
- `cilium connectivity test` - Test connectivity (can take up to 15 mins)
