# Secure Cluster Control Traffic with Network Polici ,es

- by default: all pods can communicate with each other
- using network policies we can restrict the traffic between pods (at ip and port level)
- rules are defined with NetworkPolicy in K8s manifest
- those rules configure the CNI application (f.e. cilium) to enforce the rules
    - not all CNI plugins do support network policies (f.e. flannel)

## Network Policies

- what needs to be defined in a network policy?
    - `spec.podSelector` -> selects the pods to which the policy applies, if empty, it applies to all pods in the
      namespace
    - `spec.policyTypes` -> defines the types of policies (ingress, egress, both)
    - `spec.ingress` -> defines the incoming traffic rules
    - `spec.egress` -> defines the outgoing traffic rules
      - important: it means traffic that is outgoing and initiated by the pod
      - in a DB pod for example we can block all outgoing traffic, but the db is still able to respond to incoming
        traffic
- example: allow backend and phpmyadmin to access mysql

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: np-db
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: mysql
  policyTypes:
    - Ingress
  ingress:
    - from: # first rule
        - podSelector:
            matchLabels:
              app: backend
      ports:
        - protocol: TCP
          port: 3306
    - from: # second rule
        - podSelector:
            matchLabels:
              app: phpmyadmin
      ports:
        - protocol: TCP
          port: 3306
```

- example: allow backend to only access mysql and redis; AND backend is in myapp namespace, mysql and redis in database
  namespace

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: np-backend
  namespace: myapp # namespace for pod that gets the policy
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
    - Egress
  egress:
    - to: # first rule
        - podSelector:
            matchLabels:
              app: mysql
          namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: database # namespace for the pods that are targeted
      ports:
        - protocol: TCP
          port: 3306
    - to: # second rule
        - podSelector:
            matchLabels:
              app: redis
          namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: database
      ports:
        - protocol: TCP
          port: 6379
```

- deny all traffic

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
  namespace: default
spec:
  podSelector: { }
  policyTypes:
    - Ingress
    - Egress
```

- allow all traffic to pods in namespace

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-all
  namespace: default
spec:
  podSelector: { }
  policyTypes:
    - Ingress
  ingress:
    - { }
```

## Network Policies Demo
- 3 deployments in myapp namespace
- apply [database-deployment.yaml](database-deployment.yaml), [frontend-deployment.yaml](frontend-deployment.yaml), [backend-deployment.yaml](backend-deployment.yaml)
- to test if we can access a certain pod we do the following
  - `kubectl get pods -o wide`
  - `kubectl exec backend-57bcddff64-cszjc -- sh -c 'nc -v 10.0.1.52 6379'`
    - exec in one of the backend pods
    - use netcat to connect to the IP of one of the database pods on port 6379
- network policies
  - frontend policy that only allows traffic to the backend pod -> [np-frontend.yaml](np-frontend.yaml)
  - database policy that only accepts traffic from the backend pod and without any egress traffic -> [np-database.yaml](np-database.yaml)
- verify the applied rules using netcat
  - `kubectl exec backend-57bcddff64-cszjc -- sh -c 'nc -v 10.0.1.52 6379'` -> working
  - `kubectl exec frontend-868f55fcfd-c26k9 -- sh -c 'nc -v 10.0.1.7 80'` -> fe to be working
  - `kubectl exec frontend-868f55fcfd-c26k9 -- sh -c 'nc -v 10.0.1.52 6379'` -> fe to db -> blocked
  - `kubectl exec database-5d74cb44df-5c7vr -- sh -c 'nc -v 10.0.1.7 80'` -> db to be -> blocked
