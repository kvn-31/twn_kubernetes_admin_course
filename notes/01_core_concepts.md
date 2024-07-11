# Kubernetes Core Concepts

## What is Kubernetes?

- open source container orchestration tool that automates the deployment, scaling, and management of containerized
  applications.
- originally developed by google
- rise of microservices architecture and containerization has made kubernetes very popular

Kubernetes offers

- high availability
- scalability
- disaster recovery (backup and restore)

## Main Components

### (Worker) Node

- virtual or physical machine

### Pod

- smallest unit in kubernetes
- an abstraction over a container
- usually one application per pod
- each Pod has its own IP address (internal)
- ephemeral (can die easily)

### Service

- has a permanent IP address
- -> if a pod dies, a new pod can be created and the service will route traffic to the new pod
- lifecycle of a service is independent of the lifecycle of a pod
- internal service:
  - to expose a service to other services in the cluster
- external service:
    - to expose a service to the outside world
    - usually IP:Port -> for testing purposes but not practical for production

### Ingress
- to expose a service to the outside world
- instead of exposing IP:Port, we can expose a domain name
- Ingress forwards traffic to the service

### ConfigMap
- example: application as a DB url -> if the DB url changes, we don't want to change the application code (and rebuild)
- ConfigMap is an external configuration of the application
- ConfigMap is a key-value pair
- for non-sensitive data

### Secret
- like ConfigMap but for secret data
- for passwords, certificates etc
- Secret can be referenced in Deployment/Pod (f.e. as environment variable)
- Secret is base64 encoded -> that does not make it secure, needs further measures

### Volume
- attaches physical storage to a pod
- can be remote storage (f.e. AWS S3)
- Kubernetes doesnt manage data persistence, so if a pod dies, the data is lost

### Deployment
- blueprint for a pod -> we do not create Pods, but Deployments
- specify how many replicas of a pod we want
- abstraction of pods
- DB cannot be replicated with a deployment, because it is stateful

### StatefulSet
- for stateful applications (f.e. DB)
- takes care of replication and scaling and that DB reads and writes are consistent
- is more complex than a deployment
- DBs are often hosted outside a kubernetes cluster

### DaemonSet
- equally distribute pods on the nodes
- calculates how many replicas are needed based on existing nodes
- deploys 1 replica of a pod on each node
- automatically scales up and down

## Kubernetes Architecture

## Worker Nodes/Machines
- each node has multiple pods on it
- 3 processes need to run on each node:
  - container runtime (containerd): runs the containers
  - kubelet: communicates with the container and the node -> starts and stops pods with containers inside
  - kube-proxy: forwards requests to the correct pod

## Control Plane Nodes
- manages the worker nodes
- 4 processes run on every control plane node
  - api server: cluster gateway, all communication goes through this, validates requests
  - scheduler: decides which pod goes to which node, based on resource availability, it just decides but does not do the actual work (kubelet does)
  - controller manager: watches the state of the cluster and makes changes to the cluster to bring it to the desired state (f.e. if a pod dies)
  - etcd: cluster brain, key-value store, stores the state of the cluster, no actual application data is stored here
- cluster can have multiple control plane nodes for high availability

## Control Plane Processes vs Worker Nodes in Cluster
- control plane processes are much more important, but do not require as much resources as worker nodes
- when application complexity increases, more worker nodes (and possibly also control planes) are needed

## Create K8s Components
- Kubernetes CLI (= imperative)
  - kubectl
  - limitation: complex configurations (speaking about using kubectl without files)
  - useful for testing configurations/quick tasks
- K8s config files (= declarative)
  - whole configuration in a file (IaC)
  - can be applied with kubectl
  - history of configurations

## K8s configuration file
- yaml file consisting of 3 parts
  - metadata (name of component, labels, ..)
  - configuration
  - status = automatically generated -> K8s will compare desired vs actual state (gets data vom etcd)

## YAML
- serialization language (such as XML or JSON)
- YAML name = YAML Ain't Markup Language
- YAML is a superset of JSON
```yaml
# key value pairs
app: user-authentication
port: 9000
# object
object:
  key: value
# simple list
versions:
  - 1.9
  - 2.0
# another list with simple data type
list: [1.9, 2.0]
# list with objects
objects:
  - name: object1
    version: 2
  - name: object2
    version: 3
# boolean
deployed: yes # can also be no, on or off
# multi-line stings
multilineString: |
  this is a multiline string
  this is the next line
# multi-line string parsed to one line
multiSingleLineString: >
  i will be
  interpreted
  as 
  a single line
# env variables
value: $ENV_VARIABLE
# placeholders
metadata: 
  name: {{ .Values.service.name }} # value will be replaced
# separate multiple configurations in one file
---
# here starts the new "file"
```

