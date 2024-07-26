# Deployment Strategies - Rolling Update

- how to update applications running in a K8s cluster
- when updating the deployment, what happens to the deployment and the pods?
- will old pods be deleted before new pods are started -> will this result in application downtime?
- what if new image version has issues -> how to rollback to the previous version?

## ReplicaSet

- when Deployment is created an application rollout is created and a ReplicaSet is created in the background
- ReplicaSet ensures that the desired number of pods are running at all times
- Deployment -> creates ReplicaSet -> creates Pods

## Deployment Strategies

- when we update the deployment, a new ReplicaSet is created
- but in which order do pods get removed and new ones created?
- 3 strategies
    - `Recreate`: all existing pods are killed before new ones are created -> application downtime
    - `Rolling Update`: instead of removing all pods at once, it deletes on pod and replaces with a new one, one after
      the other -> no downtime; default strategy
    - for these two strategies the old ReplicaSet remains in the cluster with zero pods, and new ReplicaSet with the new
      pods
    - `Blue/Green Deployment` (Red/Black Deployment): create a new environment with the new version of the application
      and switch traffic to the new environment -> no downtime and at all times the traffic is routed to the same environment; requires more resources
- Update Strategy is defined in Deployment configuration
    - `kubectl describe deployment NAME` -> `StrategyType: RollingUpdate`

## Rolling Update Strategy

- `maxUnavailable`: maximum number of pods that can be unavailable during the update -> by this it does not need to do
  one after another in big clusters
- `maxSurge`: maximum number of pods that can be created above the desired number of pods
- Rollout History
    - an Update creates revisions/a history of the deployment
    - `kubectl rollout history deployment NAME` -> shows the history of the deployment
- Rollback
    - `kubectl rollout undo deployment NAME` -> roll back to the previous version
    - `kubectl rollout undo deployment NAME --to-revision=2` -> roll back to a specific revision
    - `kubectl rollout status deployment NAME` -> shows the status of the rollout
