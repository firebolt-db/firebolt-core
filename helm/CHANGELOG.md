# 0.3.7

* fix: expose UI sidecar port (9100) in services when `uiSidecar=true`

# 0.3.6

* reduce initial delay in probes from 30s to 3s
* bump individual probe request timeout from 3s to 10s

# 0.3.5

* add `fsGroupChangePolicy` value (defaults to `"OnRootMismatch"`) to speed up pod startup on large volumes

# 0.3.4

* fix: use priority class also for statefulsets
* fix: add `publishNotReadyAddresses: true` to the all-nodes headless service when `useStatefulSet=false`

# 0.3.3

* add `podAnnotations` value

# 0.3.2

* add `image.pullPolicy` value

# 0.3.1

* `useStatefulSet=false` is now the default; NOTE: this switch causes new PVCs to be created and used, statefulset PVCs are not deleted but not used either

# 0.3.0

* `nonRoot=true` is now the default

# 0.2.1

* remove `pvcPrefixOverride`

# 0.2.0

* add `useStatefulSet=true`; NOTE: switching to `useStatefulSet=false` causes new PVCs to be created and used, statefulset PVCs are not deleted but not used either
* set `nonRoot=false` by default
* add `pvcPrefixOverride` to preserve PVCs across statefulset/multi-deployment versions

# 0.1.0

* initial version
