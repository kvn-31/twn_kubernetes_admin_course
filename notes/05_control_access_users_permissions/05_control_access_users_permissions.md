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

## Demo Project - Users & Permissions
- we want to use the certificate auth method
- goals:
  - generate a client key for a user, sign it by K8s CA (by sending CSR), approve CSR, get signed certificate
  - assign permissions to the user and validate the permissions
  - create ServiceAccount & add permissions

### Create User Account / Generate client key
- the whole process is described in the [kubernetes documentation](https://kubernetes.io/docs/reference/access-authn-authz/certificate-signing-requests/#normal-user)
- `openssl genrsa -out dev-tom.key 2048` to generate a private key file
- `openssl req -new -key dev-tom.key -subj "/CN=tom" -out dev-tom.csr` generate the CSR, the subject is Tom -> Name that K8s will use to validate the request
- next step: create a resource for the CSR in kubernetes -> see [documentation](https://kubernetes.io/docs/reference/access-authn-authz/certificate-signing-requests/#create-certificatessigningrequest)
- [dev-tom-csr.yaml](dev-tom-csr.yaml)
- `kubectl apply -f dev-tom-csr.yaml`
- `kubectl get csr` -> is in pending state
- `kubectl certificate approve dev-tom` approve a certificate with name dev-tom
- `kubectl get csr dev-tom -o yaml` print out the signed certificate in yaml format
  - copy the certificate and use in next command
- `echo 'COPIEDCERTIFICATE' | base64 --decode > dev-tom.crt` decode the base64 certificate and save as crt file
- `kubectl cluster-info` to get the cluster ip
- `mv ~/.kube/config .` move the config to current folder temporarily to not override auth data that is stored in there with the next command(s)
- `kubectl --server https://172.31.27.170:6443 --certificate-authority /etc/kubernetes/pki/ca.crt --client-certificate dev-tom.crt --client-key dev-tom.key get pod` use the certificates and key of user tom for the get pod command, should return a Forbidden error from the server
- next step: create a kube config file for our user tom
- `cp config dev-tom.conf` -> duplicate our admin config and replace values for user tom
  - replace all accordances with admin user to dev-tom
  - client-certificate-data: either replace with base64 encoded certificate (better) OR replace with client-certificate and link to the crt file (use absolute path)
  - client-key-data: either replace with base64 encoded private key (better) OR replace with client-key and link to the .key file (use absolute path)
  - `base64 dev-tom.crt | tr -d "\n"`to base64 encode
- `kubectl --kubeconfig dev-tom.conf get pod`
- ad kube admin we are done -> take kubeconfig, crt and key file and pass to user
