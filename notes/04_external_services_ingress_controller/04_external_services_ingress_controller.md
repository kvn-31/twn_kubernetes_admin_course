# External Services and Ingress Controller

## NodePort

- exposes a service on each worker node's IP at a static port -> accessible outside the cluster
- port range is 30000-32767 -> was defined before in the SecurityGroup in AWS

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
  labels:
    app: nginx
    svc: test-nginx
spec:
  type: NodePort
  selector:
    app: nginx
  ports:
    - protocol: TCP
      port: 8080 # port on the service
      targetPort: 80 # port on the pod (containerPort)
      nodePort: 30000 # port that will be exposed on each worker node, must be in the range 30000-32767
```

## LoadBalancer
- NodePort is not the best solution for production as it is not user-friendly and also insecure & messy as it opens a lot of ports on the worker nodes
- same syntax as above can be used with the only difference that the type is `LoadBalancer`
- creates loadbalancer outside the cluster -> entry point to the cluster
- loadbalancer routes the traffic to one of the worker nodes on the NodePort which is then forwarded to the clusterIP
- the LoadBalancer is created by cloud platforms that offer K8s managed services
- on self-managed K8s clusters, the LoadBalancer is not created automatically -> needs to be created manually
  - on premise solution or
  - on AWS -> EC2 -> LoadBalancer -> Application LoadBalancer
    - same availability zone as worker nodes (two need to be selected, choose the one where worker nodes are and another one)
    - Listeners: create Target Group -> Instances -> Port 30000 (in our case) -> in next step add the worker nodes
    - Select the Target Group in the LoadBalancer
  - While the LoadBalancer is creating we can modify the attached security group to allow traffic from our ip (All Traffic -> My IP)
  - the LoadBalancer has an IP address, but also a DNS name that can be used to access the service
  - use this DNS name to access the service

### LoadBalancer vs NodePort vs ClusterIP
- they do not replace each other but are basically built on top of each other
- LoadBalancer -> NodePort -> ClusterIP
- with LoadBalancer we are basically using all three types in one service


## Ingress
- scenario: we have multiple services, and we want to access them with a single IP address and not through multiple LoadBalancers (that are all entrypoints)
- also: we want to use domain names instead of IP addresses
- and each LoadBalancer exposes a service on a different port
- each LoadBalancer costs money
- also: we want to use SSL certificates
- using a LoadBalancer all of these issues would need to be configured outside the cluster
- solution: ingress
  - K8s component -> inside the cluster -> still needs to be exposed via NodePort or LoadBalancer -> one NodePort/LoadBalancer for all services = single entry point
  - configures routing
  - configures https
example ingress.yaml:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: minimal-ingress
spec:
  rules:
    - host: myapp.com # traffic to this host will be forwarded to the internal service
      http:
        paths:
        - path: / # could be /app1, /app2, /app3
          pathType: Prefix
          backend:
            service:
              name: myapp-internal-service
              port:
                number: 8080 # port on the service
```
example internal-service.yaml
```yaml
apiVersion: v1
kind: Service
metadata:
    name: myapp-internal-service
spec:
  selector:
        app: myapp
  ports:
    - protocol: TCP
      port: 8080
      targetPort: 80
```

### Ingress Controller
- defining an Ingress resource is not enough -> we need an Ingress Controller
- is a pod that runs in the cluster and evaluates all Ingress rules
- entrypoint to the cluster, manages redirections
- there are different Ingress Controllers available
  - K8s Nginx Ingress Controller
  - Traefik <- 3rd party
- different setups
  - using cloud service providers (out of box K8s solutions)
    - use Cloud Load Balancer -> this will direct to the Ingress Controller (most common strategy)
    - no need to c reate Load Balancer manually
  - bare metal environments
    - entrypoint needs to be configured manually
    - sits either inside of cluster or outside as separate server
    - example: external proxy server -> separate server with public ip address -> entrypoint to cluster

### Ingress Use Cases
- multiple paths (such as /app1, /app2, /app3) -> all to different services
  - simply defined in the Ingress resource using the `path` field
- multiple sub-domains or domains
  - for example analytics.myapp.com, shopping.myapp.com, blog.myapp.com
  - each domain can be forwarded to a different service
  - specified in the Ingress resource using the `host` field
- Configure TLS certificate
  - using the `tls` field in the Ingress resource
  - add a secret with the certificate and key
  - refer to the secret name in the Ingress resource
  - rules for the secret:
    - secret needs to be in the same namespace as the Ingress resource
    - data keys need to be `tls.crt` and `tls.key`
    - values are file contents, base64 encoded, not file names
