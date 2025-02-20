# firebolt-core

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: preview-rc](https://img.shields.io/badge/AppVersion-preview--rc-informational?style=flat-square)

Firebolt Core on Kubernetes

**Homepage:** <https://github.com/firebolt-db/firebolt-core/tree/main/helm>

## Source Code

* <https://github.com/firebolt-db/firebolt-core/tree/main/helm>

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| deployment.securityCapabilities | object | `{"add":["IPC_LOCK","SYS_NICE"]}` | security capabilities which will be used by each pod |
| deployment.securityContext | object | `{"readOnlyRootFilesystem":false}` | security context which will be used by each pod |
| deployment.storageSpec.accessModes[0] | string | `"ReadWriteOnce"` |  |
| deployment.storageSpec.resources.limits.storage | string | `"1Gi"` |  |
| deployment.storageSpec.resources.requests.storage | string | `"1Gi"` |  |
| deployment.storageSpec.storageClassName | string | `"gp3"` |  |
| deployment.terminationGracePeriodSeconds | int | `5` | give a few seconds of grace time on shutdown to allow queries to finish |
| extraLabels | object | `{}` | extra labels to assign to each pod |
| image.repository | string | `"ghcr.io/firebolt-db/firebolt-core"` | use a custom ECR repository to pull the Docker image used by the pods |
| image.tag | string | `nil` | use a custom Docker image tag; when unspecified the app version from chart will be used instead |
| nodesCount | int | `1` | number of nodes to deploy |
| readiness | bool | `true` | readiness check on each pod |
| resources | object | `{"limits":{"memory":"4Gi"},"requests":{"cpu":"1","memory":"4Gi"}}` | resources for each pod; at least 1 core is advised |

