#!/bin/bash

set -e

TERRAKUBE_NAMESPACE="terrakube"
TERRAKUBE_API_URL="http://$(kubectl get svc terrakube-api-service -n $TERRAKUBE_NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'):8080"
WORKSPACE_NAME="sample-workspace"

echo "Step 1: Verifying EKS Node Health..."
kubectl get nodes --no-headers | grep -v "Ready" && { echo "ERROR: Not all nodes are Ready"; exit 1; }
echo "EKS Nodes are Healthy."

echo "Step 2: Waiting for Terrakube Pods to be Ready..."
kubectl wait --for=condition=Ready pods --all -n $TERRAKUBE_NAMESPACE --timeout=300s

echo "Step 3: Installing Terrakube via Helm (If Not Installed)..."
if ! helm list -n $TERRAKUBE_NAMESPACE | grep terrakube; then
    helm repo add terrakube https://azbuilder.github.io/terrakube-helm-chart
    helm repo update
    helm install terrakube terrakube/terrakube --namespace $TERRAKUBE_NAMESPACE
    kubectl rollout status deployment/terrakube-api -n $TERRAKUBE_NAMESPACE
else
    echo "Terrakube is already installed."
fi

echo "Step 4: Registering Workspace in Terrakube..."
WORKSPACE_PAYLOAD=$(cat <<EOF
{
    "data": {
        "type": "workspaces",
        "attributes": {
            "name": "$WORKSPACE_NAME",
            "description": "Sample workspace",
            "terraformVersion": "1.5.7",
            "vcsRepo": {
                "identifier": "hashicorp/learn-terraform-docker-container",
                "branch": "main",
                "ingress": false
            }
        }
    }
}
EOF
)

curl -s -X POST "$TERRAKUBE_API_URL/api/v1/workspaces" \
    -H "Content-Type: application/vnd.api+json" \
    -d "$WORKSPACE_PAYLOAD" | jq

echo "Workspace registered."

echo "Step 5: Triggering Terraform Plan Execution..."
# Get Workspace ID
WORKSPACE_ID=$(curl -s "$TERRAKUBE_API_URL/api/v1/workspaces" | jq -r ".data[] | select(.attributes.name==\"$WORKSPACE_NAME\") | .id")

PLAN_PAYLOAD=$(cat <<EOF
{
    "data": {
        "type": "plans",
        "attributes": {
            "message": "Test Terraform Plan Execution",
            "workspaceId": "$WORKSPACE_ID"
        }
    }
}
EOF
)

# Trigger Plan
PLAN_RESPONSE=$(curl -s -X POST "$TERRAKUBE_API_URL/api/v1/plans" \
    -H "Content-Type: application/vnd.api+json" \
    -d "$PLAN_PAYLOAD")

PLAN_ID=$(echo $PLAN_RESPONSE | jq -r ".data.id")

echo "Terraform Plan triggered. Plan ID: $PLAN_ID"

echo "Waiting for Plan to finish..."
while true; do
    STATUS=$(curl -s "$TERRAKUBE_API_URL/api/v1/plans/$PLAN_ID" | jq -r ".data.attributes.status")
    echo "Current Plan Status: $STATUS"
    if [[ "$STATUS" == "FINISHED" || "$STATUS" == "FAILED" ]]; then
        break
    fi
    sleep 10
done

echo "Fetching Plan Output:"
curl -s "$TERRAKUBE_API_URL/api/v1/plans/$PLAN_ID/output" | jq -r ".data.attributes.text"

echo "test.sh execution completed successfully!"

