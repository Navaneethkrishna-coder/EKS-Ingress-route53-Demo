#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# ==========================================
# CONFIGURATION VARIABLES
# ==========================================
AWS_ACCESS_KEY_ID=""
AWS_SECRET_ACCESS_KEY=""
AWS_REGION=""
CLUSTER_NAME=""
VPC_ID=""
HOSTED_ZONE_ID=""

echo "=== 1. Creating Root Credentials Secret in Cluster ==="
kubectl create secret generic aws-root-creds \
  -n kube-system \
  --from-literal=AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}" \
  --from-literal=AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "=== 2. Installing AWS Load Balancer Controller ==="
helm repo add eks https://aws.github.io/eks-charts
helm repo update

# Apply CRDs explicitly
kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller/crds?ref=master"

helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName="${CLUSTER_NAME}" \
  --set region="${AWS_REGION}" \
  --set vpcId="${VPC_ID}" \
  --set extraEnv[0].name="AWS_ACCESS_KEY_ID" \
  --set extraEnv[0].valueFrom.secretKeyRef.name="aws-root-creds" \
  --set extraEnv[0].valueFrom.secretKeyRef.key="AWS_ACCESS_KEY_ID" \
  --set extraEnv[1].name="AWS_SECRET_ACCESS_KEY" \
  --set extraEnv[1].valueFrom.secretKeyRef.name="aws-root-creds" \
  --set extraEnv[1].valueFrom.secretKeyRef.key="AWS_SECRET_ACCESS_KEY"

echo "=== 3. Installing ExternalDNS ==="
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

helm upgrade --install external-dns bitnami/external-dns \
  --namespace kube-system \
  --set image.registry=registry.k8s.io \
  --set image.repository=external-dns/external-dns \
  --set image.tag=v0.18.0 \
  --set provider=aws \
  --set aws.zoneType=public \
  --set aws.region="${AWS_REGION}" \
  --set aws.credentials.accessKey="${AWS_ACCESS_KEY_ID}" \
  --set aws.credentials.secretKey="${AWS_SECRET_ACCESS_KEY}" \
  --set txtOwnerId="${HOSTED_ZONE_ID}"

echo "=== 4. Deploying Application, Service, and Ingress ==="
kubectl apply -f "$PROJECT_ROOT/k8s/01-deployment.yaml"
kubectl apply -f "$PROJECT_ROOT/k8s/02-service.yaml"
kubectl apply -f "$PROJECT_ROOT/k8s/03-ingress.yaml"

echo "=== 5. Monitoring Deployment ==="
echo "Waiting for ALB IP/DNS allocation..."
kubectl get ingress demo-ingress --watch
