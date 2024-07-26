# External Configuration with ConfigMap and Secret
- configMap and Secret are volume types
- they need to be applied before referenced in a pod (f.e. in a deployment)
- pods can consume configuration data from ConfigMaps and Secrets
  - either as individual values using environment variables
  - or as configuration files mounted into the pod using volumes
- short demo (creating a ConfigMap and a Secret and using them in a deployment):
  - [my-secret.yaml](my-secret.yaml)
  - [my-configmap.yaml](my-configmap.yaml)
  - [myapp-deployment.yaml](myapp-deployment.yaml)
  - `kubectl logs myapp-deployment-xxxxx` -> see the environment variables

## Use Configuration Files
- passing data as individual values often is not enough and configuration files are needed
- demo
  - [my-configmap-file.yaml](my-configmap-file.yaml)
  - [my-secret-file.yaml](my-secret-file.yaml)
  - [myapp-deployment-file.yaml](myapp-deployment-file.yaml)
  - `kubectl logs myapp-deployment-xxxxx` -> see the mounted files

## Update ConfigMap or Secret
- whenever a ConfigMap or Secret is updated, the pod does not automatically get the new data
- the pod needs to be restarted
- use `kubectl rollout restart deployment myapp-deployment` to restart the pod
