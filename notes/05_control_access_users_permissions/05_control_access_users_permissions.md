# Control Access with Users and Permissions
- in the cluster K8s admin need to have different rights than developers
- least privilege rule = only give the permissions that are needed

## RBAC (Role-Based Access Control)
- define access to each namespaces resources in the cluster
- role defines resources and access permissions
- role needs to be bound to a user or group = role binding
- role is limited to a ns
- for administrators use ClusterRole and ClusterRoleBinding
  - ClusterRole is a role that applies to the whole cluster
  - ClusterRoleBinding binds the ClusterRole to a user or group
- K8s does not manage users natively, but provides an interface
- external sources need to be used, such as
  - static token file
  - certificates
  - 3rd party authentication (ldap)
- admin configures service, k8s api server handles authentication

## Service Accounts
- what about application users -> not only people, but also applications and services (inside and outside the cluster) need access
- for example Prometheus, Microservices, CI/CD
- ServiceAccount resource
- ServiceAccount can be bound to a role with RoleBinding

## Role Configuration File
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: default # namespace where the role is applied
  name: pod-reader
rules:
- apiGroups: [""] # "" indicates the core API group
  resources: ["pods"] # resources in the core API group like Pods, Deployments, Services etc
  verbs: ["get", "watch", "list"] # actions on a resource
  resourceNames: ["my-pod"] # restrict access to a specific pod
```

## RoleBinding Configuration File
```yaml
apiVersion: rbac.authorization.k8s.io/v1
# This role binding allows "jane" to read pods in the "default" namespace.
# You need to already have a Role named "pod-reader" in that namespace.
kind: RoleBinding
metadata:
  name: read-pods
  namespace: default
subjects:
# You can specify more than one "subject"
- kind: User
  name: jane # "name" is case sensitive
  apiGroup: rbac.authorization.k8s.io
roleRef:
  # "roleRef" specifies the binding to a Role / ClusterRole
  kind: Role #this must be Role or ClusterRole
  name: pod-reader # this must match the name of the Role or ClusterRole you wish to bind to
  apiGroup: rbac.authorization.k8s.io
```

## ClusterRole Configuration File
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  # "namespace" omitted since ClusterRoles are not namespaced
  name: secret-reader
rules:
- apiGroups: [""]
  #
  # at the HTTP level, the name of the resource for accessing Secret
  # objects is "secrets"
  resources: ["secrets"]
  verbs: ["get", "watch", "list"]
```

## Working with RBAC resources
- `kubectl apply -f <file>` to apply the configuration
- `kubectl get roles` to list all roles
- `kubectl describe role <role-name>` to get more information about a role
- check the privileges of the current user, if admin we can check for other users
- `kubectl auth can-i get pods --as <user>` to check if a user can get pods

## Other Authorization Modes
- Node, ABAC, Webhook exist as well
- further details can be found in [documentation](https://kubernetes.io/docs/reference/access-authn-authz/authorization/)
- to see which modes are enabled the `etc/kubernetes/manifests/kube-apiserver.yaml` file can be checked (authorization-mode)

## Certificates in Kubernetes
- certificates are stored in the `etc/kubernetes/pki` directory
- who signed all those certificates?
  - kubeadm generated a CA for K8s cluster
  - this CA is not globally trusted
  - how is it working?
  - -> all clients have a copy of K8s CA -> clients can verify the server certificate
- K8s CAs are trusted within K8s by all components who have a copy of the CA
- Certificates API
  - allows to send CertificateSigningRequests (CSR)
  - every user/program can send a request

