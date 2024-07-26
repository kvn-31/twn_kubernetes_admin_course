# Liveness and Readiness Probes
- it is possible that a pod is running but the application inside the pod is not working correctly
- also, if the container inside the pod crashes, K8s does not know and it needs to be restarted manually
- this is where liveness and readiness probes come into play

## Liveness Probes
- used to perform health checks on the application inside the pod
- pod can automatically be restarted if the liveness probe fails
- liveness probe -> pings the application inside the pod every x seconds
- 3 types
  - exec probe: executes a specified command to check the health of the application
  - TCP probe: kubelet makes probe connection at the node, not in the pod -> checks if it is possible to connect to the port
  - HTTP probe: application exposes and endpoint, kubelet makes an HTTP request this ep-> checks if the application is working correctly

## Readiness Probes
- Liveness probe only works after the container started, but does not cover the startup process
- Readiness probe lets K8s know that an application is ready to accept traffic
- some applications might need minutes to start up
- without a readiness probe, K8s assumes that the application is ready immediately after the container started
- [12_liveness_readiness_probes.md](12_liveness_readiness_probes.md)
```yaml
    - image: nginx:1.24
      name: myapp-container
      ports:
        - containerPort: 80
      readinessProbe:
        tcpSocket:
          port: 80 # check that port 80 is open and accessible
        initialDelaySeconds: 10 # wait 10 seconds before running the probe
        periodSeconds: 5 # run the probe every 5 seconds
      livenessProbe:
        tcpSocket:
          port: 80 # check that port 80 is open and accessible
        initialDelaySeconds: 5 # once readiness is done, wait 5 seconds before running the liveness probe
        periodSeconds: 15 # run the liveness probe every 15 seconds
```
