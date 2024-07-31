# Troubleshooting
There are many things that can go wrong, this section will show the most ways to troubleshoot issues.

## Troubleshooting Applications
- is pod running?
- is pod registered in service?
- is service forwarding the request?
  - `kubectl get ep` to check endpoints
  - `kubectl describe svc NAME` to check service
- is service accessible?
  - use netcat `nc SERVICEIP SERVICEPORT` to check if service is accessible
  - ping the service `ping SERVICENAME`
- check application logs
  - `kubectl logs PODNAME`
- check pod status and recent events -> in some cases the container inside the pod is crashing/failing to start -> no logs
  - `kubectl describe pod PODNAME`

## Debug with temporary Pods
- the pod network is different from the cluster node network
- a container lives as long as the process inside it is running -> exits after the process is done
  - for Docker images this can be checked in docker hub -> tags -> click on version and see `CMD`
  - `CMD`: defaults for an executing container
  - `ENTRYPOINT`: preferred for executable that should always run, allows to append other commands
  - a docker image can have both, `ENTRYPOINT` and `CMD` -> Entrypoint defines the process that starts the container, cmd provides the attributes
  - this maps to Kubernetes the following way:
    - `ENTRYPOINT` -> `command`
    - `CMD` -> `args`
- busybox (docker) image
  - includes tools like `nslookup`, `ping`, `ifconfig` etc
  - busybox simply starts a shell -> we need to start a process to keep the container running
  - option 1: `kubectl run debug-pod --image=busybox -it` / `kubectl exec -it debug-pod -- sh`
  - option 2 (with a configuration / args): see [bb-pod.yaml](bb-pod.yaml), the arguments/commands can be adapted as needed
  - option 3: execute command inside pod environment without entering pod by attaching a terminal
    - pass the command directly to the shell program
    - `kubectl exec -it debug-pod -- sh -c "echo 'Hello World'"`

### Bash vs SH
- bash is a superset of sh
- bash has more functionality
- some images do not have bash installed (throws executable not found error)

## Kubectl Format Output
- sometimes commands return a lot of information / would be needed to run multiple commands to get the desired output
- alternative of the output (to `yaml`) is `json`
  - `kubectl get pods -o json`
- this enables to use `jsonpath` to filter the output
  - is a query language for JSON
  - `kubectl get pod -o jsonpath='{.items[*].metadata.name}'` to get all pod names
  - `kubectl get pod -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'` to get all pod names with new line
  - `kubectl get pod -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.podIP}{"\t"}{.status.startTime}{"\n"}{end}'` to get pod name, pod IP and start time with tab separated
  - not intuitive -> might be helpful to write a script that uses a jsonpath query
- custom column names:
  - `kubectl get pods -o custom-columns=POD_NAME:.metadata.name,POD_IP:.status.podIP,CREATED_AT:.status.startTime` to get pod name, pod ip, start time

## Troubleshoot Kubelet and Kubectl issues
- generally it makes sense to check the logs `journalctl -u kubelet -f`
- faced the issue that containerd had permission problems on ubuntu, [see this solution](https://www.reddit.com/r/kubernetes/comments/1byq52f/comment/lb7h1wc/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button)

### Worker Node is in NotReady State
- most probably the kubelet is not running
- sh into the node and check the kubelet status
  - `service kubelet status`
  - `journalctl -u kubelet` for more information
  - for configuration issues check the file that is listed as `Drop-In` in the output of the status command using vim/cat
  - `systemctl daemon-reload` and `systemctl restart kubelet` to restart the kubelet service (after changed config f.e.) (sudo might be needed)

### Kubectl connection issue
- for example: the command hangs and there is no output
- check the kubectl configuration in the `~/.kube/config` file
  - certificate-authority-data -> copy and decode, compare to the actual certificate sitting in the `/etc/kubernetes/pki` directory
  - server -> go to control plane or AWS console -> check if the ip address is the same
  - issue found? -> vim ~/.kube/config and fix the issue -> should work now
 
