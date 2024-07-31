# Secure Cluster Control Traffic with Network Policies

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
