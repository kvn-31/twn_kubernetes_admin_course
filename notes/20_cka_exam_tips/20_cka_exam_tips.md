# CKA Exam tips

## Use Imperative kubectl commands
- use to quickly create resources that do not need extensive configuration
  - service account
  - role
  - rolebinding
- examples
  - `kubectl run mypod --image=nginx`
  - `kubectl create deployment nginx-deployment --image=nginx` or also with `--replicas=2`
  - `kubectl expose deployment nginx-deployment --type=NodePort --name=nginx-service`
- get used to `--help`
- generate boilerplate manifests using `--dry-run=client -o yaml > myservice.yaml`

## Use Shortcuts
- `alias k=kubectl` create an alias for kubectl command
- `export do="--dry-run=client -o yaml"` -> then use like `kubectl create service clusterip myservice --tcp=80:80 $do > myservice.yaml`

## Temp File when editing Deployments
- in a running pod we cannot edit all specifications (f.e. add/remove containers, add volumes)
- -> normally we would need to delete deployment and re-apply updated manifest
- when using `kubectl edit` also if they could not be applied are saved to a temp file (location is shown after exiting edit mode)

## Practice commands
- `kubectl scale --replicas=3 deployment/mysql` -> scale deployments up and down
- filter resources
  - display all nodes which dont have taints no schedule
  - display all ready nodes
  - display all pods that have resource requests set
  - list all pods running on worker1
- `kubectl top pod ...` display resource usage on pods or nodes
- `kubectl config set-context --current --namespace=some-ns` switch default ns

## Working with root user
- normally we are not working with a root user, so it can help to switch to root user `sudo -i` when doing a lof installations that require sudo

## Be careful of session switches
- as a kubernetes admin there are multiple switches of sessions (f.e. from own laptop to remote server, to control plane node, to control plane as root, to worker node)
- pay attention which server and user you are

## Exam questions
- two types:
- create k8s resources
- textual answers (saved to file provided) -> must be in right environment

## Multiple clusters
- exam consists of multiple clusters -> at beginning of each question the command is provided
- pay attention to be in the right cluster/environment/user etc when answering the question

## Official Documentation
- during exam -> only use official documentation and one single browser page

## Install K8s cluster
- no cluster needs to be installed from scratch
- but knowing how it is created is a huge advantage
  - knowing where manifest files of control plane components are located
  - how certificate creation is working
