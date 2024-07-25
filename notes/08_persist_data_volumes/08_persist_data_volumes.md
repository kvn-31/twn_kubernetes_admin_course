# Persist Data in Kubernetes (Volumes)
- by default, containers are ephemeral, meaning that they are not meant to store data. When a container crashes, the data is lost. To persist data, we can use volumes.
- data persistence needs to be configured for each application
- requirements:
  - storage must not depend on the pod lifecycle
  - storage must be available on all nodes (because we do not know where the pod will be scheduled)
  - storage needs to survive if the cluster dies

## Persistent Volumes
- a cluster resource
- an abstract component, needs actual physical storage
- in the specification, we define the storage class, access mode, and size
- Kubernetes does not care about the storage, administrators need to decide
  - what type of storage
  - create / manage (f.e. backups etc) by themselves
- PVs are not namespaced, they are cluster-wide resources
- if claimed, it is not available for other PVCs anymore
- see [documentation example](https://kubernetes.io/docs/tasks/configure-pod-container/configure-persistent-volume-storage/)

### Local vs Remote Volume Types
- local volume types violate 2nd and 3rd requirement (see above) -> tied to a specific node and do not survive cluster crashes
- -> we should almost always use remote volume types

### Who Creates PVs? Devs vs Admins
- admins provision the storage and create the PVs
- Devs need to know the storage requirements of their application
- Devs need to use the storage using persistent volume claims (PVCs)

### Persistent Volume Claims
- an application has to claim that volume storage
- for this purpose, we use persistent volume claims (PVCs)
- simplified:
  - pvc claims a storage with certain size, access mode, and characteristics
  - whatever PV matches the PVC requirements, it will be bound to the PVC
  - the PVC is then added to the pod configuration (volumes attribute)

### Levels of Volume Abstractions
- Pod requests the volume through a PVC
- Claim tries to find a PV in the cluster that matches the claim
  - Claims must be in the same namespace as the pod
- Volume has an actual storage backend (f.e. NFS, EBS, etc)
- Volume is mounted into the pod -> then into the container (specifying a path in the pod configuration)
- now container (application inside the container) can use it
- Why are so many abstraction levels needed?
  - one major benefit is the separation of concerns between Devs and Admins (see above)
  - Devs know the storage requirements of their application, but do not care about the infrastructure
  - another benefit is that if we want to change the PV, we can do it without changing the pod configuration
- check StorageClass below for more abstraction

## ConfigMap and Secret
- are local volume types, not created via PVs and PVCS
- managed by Kubernetes
- they are used to pass configuration data, certificates etc into the pods
- a pod can use all different types of volumes at the same time
  - f.e. a PV, a ConfigMap, and a Secret

## Storage Class
- consider a cluster with hundreds of applications -> creating and managing hundreds of PVs manually can be tedious and time-consuming
- StorageClass component solves this problem
- StorageClass provisions PVs dynamically when a PVC claims it
- is another abstraction layer
- using a provisioner -> each storage backend has its own provisioner
  - internal provisioners (name starts with `kubernetes.io`)
  - external provisioners
- in the PVC config file, we can specify the storageClassName attribute which requests a PV from a specific StorageClass
  - Pod requests storage via PVC
  - PVC requests storage from a StorageClass
  - SC creates PV that matches the requirements

## HostPath Volume
- a local volume type (on the node)
- simple to configure
- for single node testing -> for multi node cluster use local volume types
- have many security and reliability issues -> avoid when possible
- see [pv-hostpath.yaml](pv-hostpath.yaml)

## Apply PV and PVC
- after applying the PV and PVC, the PVC will be bound to the PV
- to check this run `kubectl get pv` and `kubectl get pvc` -> the status should be `Bound`
- -> the PV is not available for other PVCs anymore

### Example: MySQL deployment
- Pre-Requisite PV and PVC done (using HostPath) see [pv-hostpath.yaml](pv-hostpath.yaml)
- creating Deployment for mysql [mysql-deployment.yaml](mysql-deployment.yaml)
- after applying check the pod with kubectl describe pod -> see the volumes and mounts
- `kubectl exec -it mysql-deployment-xxxx -- bash` -> `ls /var/lib/mysql` -> see the data
- sh into worker node (where pod is) -> `ls /mnt/data` -> see the data

## EmptyDir Volume
- example: sidecar container wants to log and needs shared data from main container
- no need to be persistent
- also good for temporary storage (f.e. cache)
- suitable for multi-container pods
- all containers can read and write same files in emptyDir volume
- emptyDir starts empty ... _badumm tss_
- no PV or PVC needed
- is defined in the pod configuration file (Deployment f.e.)
- example: [nginx-deployment-emptydir.yaml](nginx-deployment-emptydir.yaml)
- `kubectl logs nginx-deployment-68d98bddb-9n7pv -c log-sidecar` -> see the logs
