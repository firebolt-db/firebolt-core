# firebolt-core

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: preview-rc](https://img.shields.io/badge/AppVersion-preview--rc-informational?style=flat-square)

Firebolt Core on Kubernetes

**Homepage:** <https://github.com/firebolt-db/firebolt-core/tree/main/helm>

## Source Code

* <https://github.com/firebolt-db/firebolt-core/tree/main/helm>

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` | affinity allows you to configure pod affinity and anti-affinity. See: https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/ |
| customNodeConfig | string | `nil` | custom configuration for nodes |
| deployment.hostPathStorageEnabled | bool | `false` | `deployment.storageHostPath` is used instead. Only one mode is active at a time. |
| deployment.storageHostPath | object | `{"path":"/var/lib/firebolt-core","type":"DirectoryOrCreate"}` | hostPath settings used when hostPathStorageEnabled=true |
| deployment.storageHostPath.path | string | `"/var/lib/firebolt-core"` | path on the node's filesystem to store data |
| deployment.storageHostPath.type | string | `"DirectoryOrCreate"` | hostPath type, e.g. DirectoryOrCreate, Directory, File, etc. |
| deployment.storageSpec.accessModes | list | `["ReadWriteOnce"]` | PersistentVolumeClaim spec used when hostPathStorageEnabled=false. Ignored when hostPathStorageEnabled=true. |
| deployment.storageSpec.resources.limits.storage | string | `"1Gi"` |  |
| deployment.storageSpec.resources.requests.storage | string | `"1Gi"` |  |
| deployment.terminationGracePeriodSeconds | int | `5` | give a few seconds of grace time on shutdown to allow queries to finish |
| extraLabels | object | `{"firebolt/product":"core"}` | extra labels to assign to each pod |
| image.repository | string | `"ghcr.io/firebolt-db/firebolt-core"` | use a custom ECR repository to pull the Docker image used by the pods |
| image.tag | string | `nil` | use a custom Docker image tag; when unspecified the app version from chart will be used instead |
| memlockSetup | bool | `true` | automatically attempt to set memlock limits on container startup; not necessary if your nodes already have a large enough memlock limit. |
| nodeSelector | object | `{}` | nodeSelector allows you to configure a node selection constraint. See: https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#nodeselector |
| nodesCount | int | `1` | number of nodes to deploy |
| nonRoot | bool | `true` | enable non-root mode, requires a compatible Firebolt Core docker image; recent images are all non-root |
| podMonitor | bool | `false` | deploy a PodMonitor for Prometheus metrics scraping |
| readiness | bool | `true` | readiness check on each pod |
| resources | object | `{"limits":{"memory":"4Gi"},"requests":{"cpu":"1","memory":"4Gi"}}` | resources for each pod; at least 1 core is advised |
| securityContextCapabilities | object | `{"drop":["ALL"]}` | specify custom security context capabilities for firebolt container |
| serviceAccount | string | `"default"` | service account which pods will use for their identity |
| tolerations | list | `[]` | tolerations allows you to configure pod tolerations. See: https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/ |
| uiSidecar | bool | `false` | deploy 1 Core UI sidecar for each node |
| updateStrategy | string | `"RollingUpdate"` | sets the update strategy for the statefulset; using the default 'RollingUpdate' requires no manual intervention. See: https://docs.firebolt.io/firebolt-core/firebolt-core-operation/firebolt-core-deployment-k8s#updating-firebolt-core-version |
| utilitiesImage | string | `"debian:stable-slim"` |  |

