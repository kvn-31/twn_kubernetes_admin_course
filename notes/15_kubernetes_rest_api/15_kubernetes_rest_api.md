# Kubernetes Rest API
- using kubectl we are already interacting with the Kubernetes API
- `kubectl config view` -> shows the configuration of the kubectl including the API server and certificate-authority-data
- second way: using the REST API directly
- third way: using client libraries (e.g. Python, Go, Java)

## REST API
- different ways to interact with the API
    - `kubectl proxy --port=8080 &` -> kubectl will act as reverse proxy
      - simple and effective way
      - `curl http://localhost:8080/api/`
      - needs kubectl and configuration, not useful for automation/scripting
    - without kubectl proxy
      - we need to pass authentication
      - best: with a user with limited permissions -> service account

### Create Service Account and use Token
- `kubectl create serviceaccount myscript`
- apply [myscript-role.yaml](myscript-role.yaml)
- `kubectl create rolebinding script-role-binding --role=script-role --serviceaccount=default:myscript`
- apply [script-token.yaml](script-token.yaml)
- quick note: was not working as expected, used [kvn-service-acc-secret.yaml](kvn-service-acc-secret.yaml) which was working then (no idea why)
- `TOKEN=PASTEDTOKEN | base64 --decode | tr -d '\n')`
- `kubectl config view` -> store in `SERVER` variable
- `curl -X GET $SERVER/api --header "Authorization: Bearer $TOKEN" --cacert /etc/kubernetes/pki/ca.crt` (or instead of --cacert use --insecure)

### API
- find official API documentation [here](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.30/)
- there are also official/non-official client libraries available
- see [Programmatic Access](https://kubernetes.io/docs/tasks/administer-cluster/access-cluster-api/#programmatic-access-to-the-api)

