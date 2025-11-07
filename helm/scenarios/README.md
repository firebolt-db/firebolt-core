# Helm Chart Deployment Scenarios

This directory contains different values files for testing various deployment configurations of the Firebolt Core Helm chart.

## Available Scenarios

### minimal.yaml
Basic deployment scenario with minimal configuration.
- Single node deployment
- Standard resource allocation (1 CPU, 4Gi memory)
- Uses default PVC-based storage

### with-monitoring.yaml
Deployment with Prometheus monitoring enabled.
- 2-node deployment for high availability
- PodMonitor enabled for metrics scraping
- Higher resource allocation (2 CPU, 8Gi memory)
- Additional labels for monitoring and environment tracking

### hostpath-storage.yaml
Deployment using hostPath storage instead of PVCs.
- Useful for local development or bare-metal deployments
- Single node configuration
- Storage mounted directly from node filesystem at `/var/lib/firebolt-core`

### with-ui-sidecar.yaml
Deployment with the Core UI sidecar container enabled.
- Includes web UI for monitoring and management
- Single node configuration
- UI accessible on port 9100

## Usage

To deploy with a specific scenario:

```bash
helm install firebolt-core ./helm -f ./helm/scenarios/minimal.yaml
```

Or to test rendering:

```bash
helm template firebolt-core ./helm -f ./helm/scenarios/minimal.yaml
```

## Adding New Scenarios

When adding new scenario files:
1. Create a new YAML file in this directory
2. Start with `---` document marker
3. Override only the values that differ from defaults in `values.yaml`
4. Ensure the file passes yamllint: `yamllint -c .yamllint-helm helm/scenarios/your-scenario.yaml`
5. Test with helm lint: `helm lint helm/ -f helm/scenarios/your-scenario.yaml`
6. Validate the rendered output: `helm template test helm/ -f helm/scenarios/your-scenario.yaml | yamllint -c .yamllint-helm -`


