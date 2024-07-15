# Build Cluster from scratch
- example of a cluster setup
- 2 worker nodes, 1 control plane on Ubuntu servers
- self-managed cluster on aws

## Pre-Requisite AWS Basics
- VPC
  - virtual private cloud
  - isolated network in the cloud
  - before cloud computing -> physical data centers
  - VPC = virtual representation of a data center
  - VPC has a range of IP addresses (internal IPs)
  - Subnets
    - VPC can be divided into subnets
    - subnet is like a private network inside a network
    - have their own IP Address range
    - subnets can be public or private -> assign public IP address
    - for each AZ at least one subnet
  - Internet Gateway
    - to connect VPC to the internet
  - NACL (Network Access Control List)
    - firewall for subnets
    - to configure access on subnet level
  - Security Groups
    - firewall for EC2 instances
    - to configure access on instance level
  - span all the AZs in a region
- Availability Zones (AZs)
  - data centers in a region
  - multiple AZs in a region

## AWS Setup
- created 3 EC2 instances
  - 1 for control plane (T2.Medium)
  - 2 for worker nodes (T2.Medium to save costs, but more realistic would be T2.Large)
- connect using SSH
  - move the pem file to .ssh folder
  - `chmod 400 <pem file>`
  - `ssh -i <pem file> ubuntu@<public ip>`
  - if needed we can always switch to root user using `sudo -i`

## Pre-Requisite TLS Certificates
- anytime sensitive data is exchanged the connection needs to be secured
- -> no plain text data should be transmitted but encrypted data
- symmetric encryption: same key for encryption and decryption
  - random string is used to encrypt the data = encryption key
  - same key is used to decrypt the data
  - problem: how to exchange the key securely?
- asymmetric encryption: public and private key
  - separate keys for encryption and decryption
  - public key is used to encrypt the data
  - private key is used to decrypt the data
- certificate authority (CA)
  - data is encrypted, but hacker could impersonate the server
  - for example: route the traffic to their own server
  - -> how can a client validate the public key?
  - answer: with certificates
  - admins of the real website get their public key certified by a CA
  - CA provides a certificate with the public key, name of website and subdomains and a signature of CA
  - browser validates certificate
- client certificates
  - also the server needs to verify that it is talking to the correct client
  - client certificates are used for that
  - also signed by CA
  - happens in background
- trusted vs untrusted certificates
  - trusted: signed by a CA
  - untrusted: self-signed
  - there is a list of all trusted CAs on the operating system
  - browser will show a warning if a certificate is untrusted
- how to get a certificate
  - for example use openssl -> create key-pair, generate certificate signing request, CA validates and signs the certificate
  - this whole infrastructure is called PKI (public key infrastructure)

## K8s cluster installation
on control plane & worker:
1. install container runtime
2. install kubelet
3. kube proxy

only on control plane:
- deploy api, scheduler, controller manager and etcd as pods 

### Chicken - Egg Problem
- how to deploy the control plane components without a control plane?
- solution: static pods
  - are managed directly by kubelet daemon
  - without control plane
  - once container runtime and kubelet are running -> static pods can be started

### Secure communication between pods
- everything needs a certificate
- generate a self-signed CA certificate for the cluster (root CA)
- sign all client and server certificates with this CA
- stored in `/etc/kubernetes/pki`
- certificates
  - server certificate for API server endpoint
  - client certificate for scheduler, controller manager
  - server certificate for etcd and kubelet
  - client certificate for api server to talk to kubelets and etcd
- every client needs to be authorized -> each component gets certificate signed by same CA
- Kubernetes admin also need a client certificate, also signed by the same CA (our cluster root CA)

## Kubeadm
- doing all those steps mentioned above is a lot of work, error-prone and time-consuming
- kubeadm is a tool to bootstrap a best-practises K8s cluster
- is created and maintained by Kubernetes
- cares about bootstrapping, not about provisioning machines

## Provision and Setup Nodes
- see [Documentation](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/)
- `sudo swapoff -a` to disable swap on all nodes
- open [required ports](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#check-required-ports)
- in aws console -> security groups -> edit inbound rules
  - for control plane node:
    - TCP 6443, CIDR: 0.0.0.0/0 (all IPs)
    - TCP 2379-2380, 10250, 10259 & 10257 with CIDR of the VPC (internal IPs)
  - for worker nodes:
    - TCP 10250, 10256, CIDR of the VPC
    - TCP 30000-32767, 0.0.0.0/0 (all IPs)
- for readability rename the hostnames
  - connect to each node, `sudo vim /etc/hosts`
  - get the private ip of each node and add the following lines
```
172.x.x.x controlplane
172.x.x.x worker1
172.x.x.x worker2
```
  - as a next step on each machine, update the hostname
    - `sudo hostnamectl set-hostname controlplane` (replace controlplane with worker1 or worker2 for the other nodes)
    - now exit and reconnect to the machine, the hostname should be updated (see the tab/machine name of the terminal)

## Container Runtime
- our applications run as containers
- but also the K8s components run as containers
- -> container runtime needs to be on worker and control plane nodes
- CRI (Container Runtime Interface)
  - abstracts the container runtime
  - K8s can run with different container runtimes (containerd, cri-o, docker)
  - Docker is not only a runtime, but an entire tech stack (can build applications etc) -> more lightweight runtimes emerged (containerd, cri-o)
  - CRI defines rules what a container runtime must do to be compatible with K8s
  - containerd is the most popular runtime -> no docker commands supported, but should not be necessary for us

### Install Containerd
- _the whole setup for 1.28 is added to the [install-containerd_nana.sh](install-containerd_nana.sh) script_
- install [Pre-requisites](https://kubernetes.io/docs/setup/production-environment/container-runtimes/#install-and-configure-prerequisites)
- in control plane node execute
  - `cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
    net.ipv4.ip_forward = 1
    EOF`
  - `sudo sysctl --system`
  - verify with `sysctl net.ipv4.ip_forward` (should return 1)
  - install [Containerd](https://kubernetes.io/docs/setup/production-environment/container-runtimes/#containerd)
  - also see [containerd documentation](https://github.com/containerd/containerd/blob/main/docs/getting-started.md)
    - easier option is Option 2 - use apt-get/dnf
    - `sudo apt-get update && sudo apt-get install containerd` installs containerd
    - `sudo mkdir /etc/containerd` creates the directory for the configuration file
    - `containerd config default | sudo tee /etc/containerd/config.toml` creates the default configuration file
    - `sudo ls /etc/containerd/config.toml` to verify the file
    - `sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml` to enable systemd cgroups (see documentation) -> goes into file, finds string, replaces with true
    - `sudo systemctl restart containerd` to restart containerd and apply changed configuration
- do the same on the worker nodes -> easier using the [install-containerd_nana.sh](install-containerd_nana.sh) script
  - use scp or create on node with `sudo vim install-containerd.sh` and paste the content
  - make file executable with `sudo chmod +x install-containerd.sh`
  - execute with `sudo ./install-containerd.sh`
  - verify it is running `sudo systemctl status containerd.service`
  - verify the config was updated correctly `sudo cat /etc/containerd/config.toml | grep SystemdCgroup`

## K8s Processes (kubeadm, kubelet and kubectl)
- kubeadm needs to be installed on each node
- initialize once with `kubeadm init` (on control plane node)
  - orchestrates the whole cluster setup
  - generates /etc/kubernetes folder
  - generates self-signed CA
  - generates static pod manifests
  - kubelet will detect the manifest files and start the pods using containerd
- quick definitions
  - kubelet: starts and stops pods, runs on all machines
  - kubeadm: CLI to initialize the cluster
  - kubectl: CLI to talk to the cluster
- see [documentation](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/)
  - pick your Kubernetes version
- for V1.28 see [install-k8s-components.sh](install-k8s-components.sh)
  - create file using vim `vim install-k8s-components.sh`
  - make file executable `chmod +x install-k8s-components.sh`
  - execute `./install-k8s-components.sh`
  - can be verified with `kubelet --version` and `kubeadm version` and `kubectl version`
- initialize cluster on control plane
  - `sudo kubeadm init`
  - to see the kube-apiserver configuration `sudo cat /etc/kubernetes/manifests/kube-apiserver.yaml | less` -> can be changed/overwritten and kubelet will restart the pod
