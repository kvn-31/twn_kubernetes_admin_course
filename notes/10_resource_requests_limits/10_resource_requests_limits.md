# Resource Requests and Limits
- some containers need more resources than others
- Kubernetes allows to specify the amount of resources that a container needs
- requests is the amount of resources that the container is guaranteed to get
- K8s scheduler uses this information to decide where to place the pod
- a container can potentially (due to application issues f.e.) consume all the Node's resources
- to prevent this we can set resource limits
  - kubelet and container runtime force this limit
  - if a container starts consuming more than the requested resources, it might get killed
  - if the Node is running out of resources it will evict the pods first that have no resource definition

## Hands-On Demo
```yaml
    spec:
      containers:
        - name: my-app
          image: nginx:1.20
          resources:
            requests: # what is expected to be needed for the application to run
              memory: "64Mi"
              cpu: "250m"
            limits: # maximum amount of resources that the container can use
              memory: "128Mi"
              cpu: "500m"
        - name: logging-sidecar
```
- for more details check [nginx-deployment-with-resources.yaml](nginx-deployment-with-resources.yaml)
- defined in
  - `Mi` - Mebibytes
  - `m` - millicores, best practice maximum is 1 core
- if the values are larger than the Node's resources, the pod will not be scheduled
- `kubectl get pod -o jsonpath="{range .items[*]}{.metadata.name}{.spec.containers[*].resources}{'\n'}"` to see the resources of the pods
