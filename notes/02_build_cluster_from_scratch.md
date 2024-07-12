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
