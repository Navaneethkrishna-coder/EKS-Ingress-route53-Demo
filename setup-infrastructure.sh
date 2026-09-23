#!/usr/bin/env bash
set -e

# ==========================================
# ENTER YOUR DOMAIN NAME HERE
# ==========================================
DOMAIN_NAME="navaneethkrishna.me"
REGION="us-east-1"

echo "=== 1. Creating EKS Cluster and VPC (Takes ~10-15 mins) ==="
eksctl create cluster -f infrastructure/01-cluster-config.yaml

echo "=== 2. Fetching Auto-Created VPC ID ==="
VPC_ID=$(aws ec2 describe-vpcs \
  --region "${REGION}" \
  --filters "Name=tag:alpha.eksctl.io/cluster-name",Values="demo-eks-cluster" \
  --query "Vpcs[0].VpcId" --output text)

echo "Created VPC ID: ${VPC_ID}"

echo "=== 3. Creating Route 53 Public Hosted Zone ==="
HOSTED_ZONE_ID=$(aws route53 create-hosted-zone \
  --name "${DOMAIN_NAME}" \
  --caller-reference "$(date +%s)" \
  --query "HostedZone.Id" --output text | sed 's/\/hostedzone\///')

echo "Created Hosted Zone ID: ${HOSTED_ZONE_ID}"

echo "=== Name Servers for your Domain Registrar ==="
aws route53 get-hosted-zone --id "${HOSTED_ZONE_ID}" --query "DelegationSet.NameServers" --output table

echo ""
echo "=========================================================="
echo "INFRASTRUCTURE CREATED SUCCESSFULLY!"
echo "Use these values in your deploy-app.sh script:"
echo "VPC_ID=\"${VPC_ID}\""
echo "HOSTED_ZONE_ID=\"${HOSTED_ZONE_ID}\""
echo "CLUSTER_NAME=\"demo-eks-cluster\""
echo "AWS_REGION=\"${REGION}\""
echo "=========================================================="
