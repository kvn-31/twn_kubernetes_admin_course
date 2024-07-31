# Manage multiple clusters using kube contexts
- scenario: having multiple clusters in a company and manage all of them
- -> how to switch between them
- having a kubeconfig file, we can specify it using `kubectl --kubeconfig <path-to-kubeconfig>`
  - annoying to type this all the time
- better way: use kube contexts

## Kube Contexts
- all clusters and users are defined in the 1 kubeconfig file
- we define a context for each cluster and use the context to switch between them
- `contexts` is a section in the kubeconfig file which defines the cluster, user and namespace (by default `default`)
- `current-context` is the context that is currently active
- `kubectl config get-contexts` -> shows all contexts
- `kubectl config current-context` -> shows the current context
- `kubectl config use-context <context-name>` -> sets the current context
- to update the kubeconfig file with a new context we can use kubectl
- `kubectl config set-context --current --namespace=kube-system` -> sets the namespace for the current context to kube-system
