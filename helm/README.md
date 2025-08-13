# firebolt-core

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: preview-rc](https://img.shields.io/badge/AppVersion-preview--rc-informational?style=flat-square)

Firebolt Core on Kubernetes

**Homepage:** <https://github.com/firebolt-db/firebolt-core/tree/main/helm>

## Source Code

* <https://github.com/firebolt-db/firebolt-core/tree/main/helm>

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| deployment.persistantStorageEnabled | bool | `true` | Controls storage mode. When true, PVCs are created using `deployment.storageSpec`. When false, a `hostPath` volume is used from `deployment.storageHostPath`. |
| deployment.storageHostPath.path | string | `"/var/lib/firebolt-core"` | Node filesystem path for hostPath when `deployment.persistantStorageEnabled=false`. |
| deployment.storageHostPath.type | string | `"DirectoryOrCreate"` | hostPath type used when `deployment.persistantStorageEnabled=false`. |
| deployment.storageSpec.accessModes[0] | string | `"ReadWriteOnce"` |  |
| deployment.storageSpec.resources.limits.storage | string | `"1Gi"` |  |
| deployment.storageSpec.resources.requests.storage | string | `"1Gi"` |  |
| deployment.terminationGracePeriodSeconds | int | `5` | give a few seconds of grace time on shutdown to allow queries to finish |
| extraLabels | object | `{}` | extra labels to assign to each pod |
| image.repository | string | `"ghcr.io/firebolt-db/firebolt-core"` | use a custom ECR repository to pull the Docker image used by the pods |
| image.tag | string | `nil` | use a custom Docker image tag; when unspecified the app version from chart will be used instead |
| memlockSetup | bool | `true` | automatically attempt to set memlock limits on container startup; not necessary if your nodes already have a large enough memlock limit. |
| nodesCount | int | `1` | number of nodes to deploy |
| nonRoot | bool | `false` | enable non-root mode, requires a compatible Firebolt Core docker image |
| podMonitor | bool | `false` | deploy a PodMonitor for Prometheus metrics scraping |
| readiness | bool | `true` | readiness check on each pod |
| resources | object | `{"limits":{"memory":"4Gi"},"requests":{"cpu":"1","memory":"4Gi"}}` | resources for each pod; at least 1 core is advised |

### Storage

Exactly one storage mode is active:

- When `deployment.persistantStorageEnabled: true` (default):
  - A `volumeClaimTemplates` section is rendered on the `StatefulSet`.
  - The claim uses `deployment.storageSpec`.

- When `deployment.persistantStorageEnabled: false`:
  - No PVCs are created.
  - A `hostPath` volume named `firebolt-core-data…` is mounted, using `deployment.storageHostPath`.

Note: `deployment.storageSpec` is ignored when `deployment.persistantStorageEnabled` is false.

