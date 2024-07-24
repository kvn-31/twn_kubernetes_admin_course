# Multi Container Pods
- a pod is like a virtual operating system environment
  - own ip address
  - own ports
  - own access rules, network namespace etc

## Sidecar Container
- it is possible to run multiple containers inside a pod
  - one main
  - additional sidecar/helper containers
- usually they operate asynchronously
- talk to each other using localhost
- data can be shared
- run whole time the main container is running doing regular work
- starts same time as main container
- simple example:
```yaml
    spec:
      containers:
        - name: nginx
          image: nginx
          ports:
            - containerPort: 80
        - name: log-sidecar
          image: busybox:1.28
          command: ["sh", "-c", "while true; do echo sync app logs; sleep 20; done"]
```
- apply, check `kubectl get pods` -> see that two instead of one container is running
- to check the logs do `kubectl logs PODNAME -c log-sidecar`

## Init Container
- runs before the main container starts once
- for example:
  - set env variables
  - check system
  - wait for services to be ready
- in pod configuration file:
```yaml
      initContainers:
        - name: mydb-available
          image: busybox:1.28
          command: ["sh", "-c", "until nslookup mydb-service; do echo waiting for mydb; sleep 4; done"] #waits for mydb-service to be available
```
- running `kubectl get pods` shows Init:0/1 -> not ready yet status
- can be logged into with `kubectl logs PODNAME -c mydb-available`

