# Scheduling Pods
- pods are automatically scheduled on working nodes
- schedular decides intelligently where to place the pods
- it is also possible to specify where to place the pods using NodeName and NodeSelector

## NodeName
- simplest form of selecting a node
- [pod-worker1.yaml](pod-worker1.yaml)
```yaml
  containers:
    - name: nginx
      image: nginx
  nodeName: worker1 # Assign the pod to worker1 node
```
- `kubectl get pod nginx -o wide` -> shows the node the pod is running on (worker1)
- limitation: the nodeName is "hard coded"
- limitation: if the node is not available/has no resources, the pod will not be scheduled

## NodeSelector
- more flexible way to select a node, we can use dynamic node names
- labels can be attached to nodes
- `kubectl get node --show-labels`
- `kubectl label node worker2 type=cpu` adds a label to worker2
- [pod-worker2.yaml](pod-worker2.yaml)
```yaml
  containers:
    - name: nginx
      image: nginx
  nodeSelector:
    type: cpu # Assign the pod to a node with the label type=cpu
```
- provides more flexibility than nodeName
- limitations
  - if not enough resources are available on the node, the pod will not be scheduled
  - in big clusters more flexible expressions are needed

## Node Affinity - Assigning Pods to Nodes
- to specify more complex rules, node affinity can be used
- affinity language
- multiple rules can be defined
  - hard rules: must be fulfilled (required...)
  - soft rules: should be fulfilled (preferred...)
- uses operators
  - exists: match node that have a specific label, value does not matter
  - Gt, Lt: match nodes with a value greater or less than the specified value
  - Not In: match nodes that do not have a specific label key=value
  - DoesNotExist: match nodes that do not have a specific label key
- [pod-nodeaffinity.yaml](pod-nodeaffinity.yaml)

## Taints and Tolerations
- taints are used to repel pods from nodes, this means that pods are not scheduled on nodes with certain taints
- `kubectl describe node controlplane | grep Taint` -> has taint `NoSchedule` -> pods are not scheduled on this node
- `kubectl describe node | grep Taint` -> shows all taints on all nodes
  - `node.kubernetes.io/disk-pressure:NoSchedule` -> node has disk pressure (example)
- Taints of controlplane is set when bootstrapping the cluster with kubeadm
- but how can system pods be scheduled on the controlplane node?
- tolerations are used to tolerate taints
- toleration = allow pods to schedule on nodes with specific taints
- `kubectl describe pod -n kube-system etcd-controlplane` -> shows the tolerations of the system pods
  - `Tolerations:       :NoExecute op=Exists`

## Schedula a Pod on controlplane (using tolerations)
- [pod-with-tolerations.yaml](pod-with-tolerations.yaml)
```yaml
# if this toleration exists on a node, the pod can be scheduled on this node
  tolerations:
    - effect: NoExecute
      operator: Exists
```
- all nodes might allow this, to guarantee it is scheduled on the controlplane we can use nodeName `nodeName: controlplane`
- `kubectl get pod pod-with-toleration -o wide` -> shows the pod is running on controlplane

## Inter-Pod Affinity and Anti-Affinity
- scenario: a dynamic infrastructure (nods get added and removed based on load), we create a pod that creates logs on up to 5 additional control plane nodes -> 5 replicas specified, but when creating only one control plane node exists -> all 5 pods are scheduled on the same node
- problem: if a new control plane is added no pod replicas are scheduled onto it
- solution: Inter-Pod Anti-Affinity
- allows to constrain which nodes your pod is eligible to be scheduled based on labels on pods that are already running on the node
  - example: this pod should not run on worker1 if worker1 is already running more pods with a specific label
- What is Inter-Pod Affinity then?
  - scenario: an application works with etcd only, but etcd does not run on all control plane nodes
  - -> we only want to run the pod on control plane nodes that have etcd
- for our scenario we have the following rules:
  - Affinity: schedule only on nodes where etcd is running
  - Anti-Affinity: schedule only on nodes that do not have another replica of the pod running
- [inter-pod-affinity.yaml](inter-pod-affinity.yaml)
- having exactly one replica on each node is similar to DaemonSets
- the scheduling constraints should not be overused

## Node Affinity vs Inter-Pod Affinity
- Node affinity
  - node labels
- Inter-Pod Affinity
  - pod labels
