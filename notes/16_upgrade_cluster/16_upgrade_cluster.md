# Upgrade Kubernetes Cluster
- the goal is to have no / minimal downtime
- the upgrade consists of two main parts
  - upgrading the control plane
  - upgrading the worker nodes
- when upgrading the control plane, the control plane processes are not available, but the pods are still running -> no downtime
- management functionality is not available and crashed pods cannot be restarted
- if the control plane needs to stay available, multiple control planes are needed
- with two worker nodes and at least two pod replicas, the application should have no downtime

## Control Plane components & its versions
- what are we exactly updating on the control plane?
- kube-apiserver, kube-controller-manager, kube-scheduler, kubelet, kube-proxy, kubectl all share the same version
- etcd, coredns are dependencies of kubernetes -> will be updated
- cilium was not installed with kubeadm, so it is not part of the upgrade
- do these component need to same version? not necessarily 
  - kube-api-server must have a later version
  - controller-manager and kube-scheduler can be 1 version behind
  - kubelet and kube-proxy can be 2 versions behind
  - kubectl 1 version behind or later
- recommended: upgrade all components to the same version

## Upgrade Control Plane Components
1. upgrade kubeadm
2. upgrade control plane components and renew cluster certificates
   - important: this does not include kubelet and kubectl
3. drain nodes to remove all pods
   - kubelet will not be able to restart pods
   - all pods will be removed and node will be marked as unschedulable -> means no new pods can be scheduled on it
4. upgrade kubelet and kubectl

## Upgrade Worker Nodes
1. Upgrade kubeadm
2. execute kubeadm to upgrade all kubelet config
3. drain the node
   - pods will be rescheduled on other nodes
4. upgrade kubelet
5. change worker node back to be schedulable

## Draining Nodes
- it will first mark the node as unschedulable
- then pods that are running there will be evicted and scheduled on other nodes
- alternative to `kubectl drain` is `kubectl cordon` to mark the node as unschedulable without evicting the pods (puts in maintenance mode)
  - helpful if something that does not impact the running pods, bit would have interference issues if new pods keep getting created, is updated
- use `kubectl uncordon` to mark the node as schedulable again

## When to upgrade the cluster?
- when a fix is rolled out
- general rule: keep cluster up-to-date
- Kubernetes supports only up to 3 recent versions
- cluster is updated one version at a time (recommended)

## Upgrade Process in Detail (v1.28 to v1.29)
- a detailed set of instructions can be found in the [official documentation](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/)
- `sudo -i` to switch to root user
- upgrade the kubernetes package registry
  - `vim /etc/apt/sources.list.d/kubernetes.list` -> change the version to the new version
- `apt update`
- `apt-cache madison kubeadm` -> check the available versions
```bash
apt-mark unhold kubeadm && \
apt-get update && sudo apt-get install -y kubeadm='1.29.x-*' && \
apt-mark hold kubeadm # fixates the version
```
- `kubeadm version` -> check the version
- `kubeadm upgrade plan` -> check the upgrade plan and gives command to upgrade (version might need to be adjusted as needed)
- `kubeadm upgrade apply v1.x.x` 
- done, now update kubelet, switch back to normal user (just for next command)
- `kubectl drain controlplane` (might need `--ignore-daemonsets`)
```bash
apt-mark unhold kubelet kubectl && \
apt-get update && sudo apt-get install -y kubelet='1.29.x-*' kubectl='1.29.x-*' && \
apt-mark hold kubelet kubectl
```
- restart kubelet
```bash
systemctl daemon-reload
systemctl restart kubelet
systemctl status kubelet # check status (should be active)
```
- switch back to normal user
- `kubectl uncordon controlplane` to make the node schedulable again
- `kubectl get nodes` -> check if the node is ready and version is updated

## Upgrade Worker Nodes
- ssh into the worker node
- `sudo -i` to switch to root user
- upgrade the kubernetes package registry
    - `vim /etc/apt/sources.list.d/kubernetes.list` -> change the version to the new version
- `apt update`
```bash
apt-mark unhold kubeadm && \
apt-get update && sudo apt-get install -y kubeadm='1.29.x-*' && \
apt-mark hold kubeadm # fixates the version
```
- `kubeadm upgrade node` -> different to control plane upgrade
- on control plane node, `kubectl drain worker1` (might need `--ignore-daemonsets`)
  - if it throws error "cannot delete Pods declare no controller" -> means the pods are not managed by a controller, so they need to be deleted manually or use `--force` to ignore
- `kubectl get pod -o wide` -> now shows that all pods are running on the other node (worker2 for example)
- on worker node
```bash
apt-mark unhold kubelet kubectl && \
apt-get update && sudo apt-get install -y kubelet='1.29.x-*' kubectl='1.29.x-*' && \
apt-mark hold kubelet kubectl
```
- restart kubelet
```bash
systemctl daemon-reload
systemctl restart kubelet
systemctl status kubelet # check status (should be active)
```
- `kubectl uncordon worker1` to make the node schedulable again
- `kubectl get nodes` -> check if the node is ready and version is updated
- do the same for all worker nodes
