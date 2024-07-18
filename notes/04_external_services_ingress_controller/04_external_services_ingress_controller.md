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
