#!/bin/bash
set -euo pipefail

# Script to validate the Helm chart
# This script can be run locally or in CI

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HELM_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$HELM_DIR")"

echo "==================================="
echo "Helm Chart Validation"
echo "==================================="
echo ""

# Check for required tools
if ! command -v helm &> /dev/null; then
    echo "ERROR: helm is not installed. Please install helm first."
    exit 1
fi

if ! command -v yamllint &> /dev/null; then
    echo "ERROR: yamllint is not installed. Please install yamllint first."
    echo "  You can install it with: pip install yamllint"
    exit 1
fi

echo "✓ Required tools found: helm $(helm version --short), yamllint"
echo ""

# Step 1: Run yamllint on chart source files (non-template files)
echo "Step 1: Running yamllint on chart source files..."
echo "-----------------------------------"
# Only lint Chart.yaml, values.yaml, and scenario files
# Template files contain Go templating syntax that yamllint can't parse
if yamllint \
    "$HELM_DIR/Chart.yaml" \
    "$HELM_DIR/values.yaml" \
    "$HELM_DIR/scenarios/"; then
    echo "✓ yamllint passed"
else
    echo "✗ yamllint failed"
    exit 1
fi
echo ""

# Step 2: Run helm lint with no values
echo "Step 2: Running helm lint (no values)..."
echo "-----------------------------------"
if helm lint "$HELM_DIR/"; then
    echo "✓ helm lint passed"
else
    echo "✗ helm lint failed"
    exit 1
fi
echo ""

# Step 3: Run helm lint with scenario values
echo "Step 3: Running helm lint with scenario values..."
echo "-----------------------------------"
SCENARIOS_PASSED=0
SCENARIOS_FAILED=0
for scenario_file in "$HELM_DIR/scenarios"/*.yaml; do
    scenario_name=$(basename "$scenario_file")
    echo "Testing scenario: $scenario_name"
    if helm lint "$HELM_DIR/" -f "$scenario_file"; then
        echo "  ✓ $scenario_name passed"
        SCENARIOS_PASSED=$((SCENARIOS_PASSED + 1))
    else
        echo "  ✗ $scenario_name failed"
        SCENARIOS_FAILED=$((SCENARIOS_FAILED + 1))
    fi
done
echo ""
echo "Scenarios: $SCENARIOS_PASSED passed, $SCENARIOS_FAILED failed"
if [ $SCENARIOS_FAILED -gt 0 ]; then
    exit 1
fi
echo ""

# Step 4: Generate and validate helm template output
echo "Step 4: Generating and validating helm template output..."
echo "-----------------------------------"
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Generate template with default values
echo "Generating template with default values..."
if ! helm template firebolt-core "$HELM_DIR/" > "$TEMP_DIR/helm-template-output.yaml"; then
    echo "✗ Failed to generate template with default values"
    exit 1
fi

# Run yamllint on the generated template
echo "Running yamllint on generated template..."
if yamllint "$TEMP_DIR/helm-template-output.yaml"; then
    echo "  ✓ Default values template passed yamllint"
else
    echo "  ✗ Default values template failed yamllint"
    exit 1
fi

# Test each scenario
TEMPLATE_PASSED=0
TEMPLATE_FAILED=0
for scenario_file in "$HELM_DIR/scenarios"/*.yaml; do
    scenario_name=$(basename "$scenario_file" .yaml)
    echo "Generating template for scenario: $scenario_name"
    
    if ! helm template firebolt-core "$HELM_DIR/" -f "$scenario_file" > "$TEMP_DIR/helm-template-${scenario_name}.yaml"; then
        echo "  ✗ Failed to generate template for $scenario_name"
        TEMPLATE_FAILED=$((TEMPLATE_FAILED + 1))
        continue
    fi
    
    if yamllint "$TEMP_DIR/helm-template-${scenario_name}.yaml"; then
        echo "  ✓ $scenario_name template passed yamllint"
        TEMPLATE_PASSED=$((TEMPLATE_PASSED + 1))
    else
        echo "  ✗ $scenario_name template failed yamllint"
        TEMPLATE_FAILED=$((TEMPLATE_FAILED + 1))
    fi
done

echo ""
echo "Template validation: $((TEMPLATE_PASSED + 1)) passed, $TEMPLATE_FAILED failed"
if [ $TEMPLATE_FAILED -gt 0 ]; then
    exit 1
fi
echo ""

echo "==================================="
echo "✓ All validation checks passed!"
echo "==================================="

