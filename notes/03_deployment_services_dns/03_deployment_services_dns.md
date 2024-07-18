# Deployment, Services, DNS (Deploy Applications)

## Simple Nginx Deployment
- take [example nginx deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- create / copy a file to the control plane with the content and apply it with `kubectl apply -f <file>`

## Service
- Ports in Service and Pod
  - Service: `targetPort` is the port the service is listening on
  - Pod: `containerPort` is the port the container is listening on (needs to match containerPort)
- how to connect deployment and service (labels & selectors)
  - deployment: `metadata.labels` and `spec.selector.matchLabels` -> labels need to match -> deployment knows which pods to manage
  - service: `spec.selector` -> service knows which pods to route traffic to
- to apply `kubectl apply -f <file>` (using a simple service)
- to get the service `kubectl get svc`
- to get details `kubectl describe svc <service-name>` -> under endpoints the ip addresses of the pods should be shown
- default type is `ClusterIP` -> only accessible from within the cluster
- the service is not a running process
- a service is a virtual IP address that is accessible throughout the whole cluster
- the forwarding of traffic is done by the kube-proxy

## Labels, Selectors, and Names
- Names are unique within a namespace (for that type of resource)
- Labels are used to identify and target K8s components
- Kubernetes assigns some labels automatically

## Scale application using kubectl and record history
- if we want to test the scaling of the application we can use `kubectl scale deployment <deployment-name> --replicas=<number>` instead of applying an adapted deployment file
- problem: if we scale using kubectl there is no clear history of what happened
- solution: use the --record flag `kubectl scale deployment <deployment-name> --replicas=<number> --record` -> this will add a record to the deployment history
- the history can be found using `kubectl rollout history deployment <deployment-name>`

## Connect to a pod from another pod
- example: have a running nginx pod and create another pod that does a simple curl to the nginx pod
- create a pod with `kubectl run test-nginx-svc --image=nginx` -> no deployment behind it
- enter pod terminal with `kubectl exec -it test-nginx-svc -- bash`
- `curl http://x.x.x.x:8080` (using service ip) does the same as `curl NGINXSERVICENAME:8080`
- see below why this is possible

## Prerequisite DNS (Domain Name System)
- DNS is a system that translates domain names to IP addresses -> using google.com instead of an IP address
- the network only understands IP addresses -> DNS is needed to translate domain names
- before the rise of the internet, the local etc/hosts file was used to map domain names to IP addresses
  - even today this is the first place to look for a domain name
- Domain Names follow a hierarchical structure
  - Root -> . (dot)
  - Top-Level Domain (TLD) -> the original ones are: .com, .org, .net, .gov, .edu, .mil; now extended by country and other TLDs 
  - Second-Level Domain -> google.com, amazon.com
  - Subdomain -> www.google.com, mail.google.com
- Who manages the DNS?
  - ICANN (Internet Corporation for Assigned Names and Numbers) -> manages the root DNS servers
  - TLDs are managed by different organizations
- Fully Qualified Domain Name (FQDN) -> www.google.com.
  - the dot at the end indicates that this is the full domain name (the . stands for root domain)
- How is it working?
  - every device has a DNS client
  - the client sends a request to resolver (mostly the ISP = Internet Service Provider)
  - if address is not in cache, the resolver sends a request to the root DNS server
    - placed around the world (13)
  - the root DNS server sends the resolver to the TLD server (f.e. .com)
  - resolver asks the TLD server for the IP address
  - .com server sends the resolver to the authoritative name server
    - responsible to know everything about the domain (including the IP address)
  - IP address is sent back to the resolver
- Computer and Resolver cache the IP address

## DNS in Kubernetes
- DNS mapping is done in a centralized place = DNS server
- manages list of service names and their ip addresses
- all pods point to this nameserver
- DNS server = CoreDNS (also called kube-dns)
- is installed with the cluster in kubeadm init
- runs as a pod in the kube-system namespace (2 replicas) -> check these if DNS is not working
- `kubectl logs -n kube-system -l k8s-app=kube-dns` -> check logs of the DNS server
- in pods there is a `/etc/resolv.conf` file that points to the DNS server (to the coredns service)
- kubelet automatically configures the pods to use the DNS server by creating the `/etc/resolv.conf` file
- what happens when a pod is in a different namespace?
  - the pod can access the service in another namespace by using the service name and the namespace
  - for each namespace the dns server creates a subdomain
  - f.e. `my-service.my-namespace.svc.cluster.local` considering FQDN
    - `my-service` = Hostname of the service
    - `my-namespace` = Namespace of the service
    - `svc` = Type
    - `cluster.local` = Cluster/Root Domain
  - `curl my-service.my-namespace` works (is still a short form of the FQDN)
    - having a look at the `/etc/resolv.conf` file shows the nameserver and search domain (which includes svc.cluster.local)

## Configure Service IP Address
- default service type is ClusterIP
- exposes the service on a cluster-internal IP -> only reachable from within the cluster
- IP address range is defined in kube api server config (`/etc/kubernetes/manifests/kube-apiserver.yaml`)
  - `service-cluster-ip-range` CIDR block of IP addresses
- an alternative range can be specified running `kubeadm init --service-cidr=...`
- to change it afterwards, the `kube-apiserver.yaml` config can be edited
  - kubelet will _should_ automatically restart all affected system pods (takes some time)
  - only new services will get the new IP range
  - can be tested with a simple service `kubectl create svc clusterip test-new-cidr --tcp=80`

