# 0.2.1

* remove `pvcPrefixOverride`

# 0.2.0

* add `useStatefulSet=true`; NOTE: switching to `useStatefulSet=false` causes new PVCs to be created and used, statefulset PVCs are not deleted but not used either
* set `nonRoot=false` by default
* add `pvcPrefixOverride` to preserve PVCs across statefulset/multi-deployment versions

# 0.1.0

* initial version
