#!/usr/bin/env bash
set -e

HOSTED_ZONE_ID="Z071166022BDNZ0G6TOMR" # Replace with your Route 53 Hosted Zone ID

echo "=== 1. Deleting Ingress and Application Resources ==="
# Deleting the Ingress automatically removes the AWS ALB
kubectl delete -f k8s/03-ingress.yaml || true
kubectl delete -f k8s/02-service.yaml || true
kubectl delete -f k8s/01-deployment.yaml || true

echo "=== 2. Uninstalling Helm Controllers ==="
helm uninstall aws-load-balancer-controller -n kube-system || true
helm uninstall external-dns -n kube-system || true

echo "=== 3. Deleting Route 53 Hosted Zone ==="
if [ -n "$HOSTED_ZONE_ID" ]; then
  # Delete leftover records (excluding NS and SOA)
  aws route53 list-resource-record-sets --hosted-zone-id "$HOSTED_ZONE_ID" \
    --query "ResourceRecordSets[?Type!='NS' && Type!='SOA']" | \
    jq -c '.[]' | while read -r record; do
      aws route53 change-resource-record-sets --hosted-zone-id "$HOSTED_ZONE_ID" \
        --change-batch "{\"Changes\":[{\"Action\":\"DELETE\",\"ResourceRecordSet\":$record}]}" || true
    done

  aws route53 delete-hosted-zone --id "$HOSTED_ZONE_ID" || true
fi

echo "=== 4. Deleting EKS Cluster and Auto-Created VPC ==="
eksctl delete cluster -f infrastructure/01-cluster-config.yaml --wait

echo "=== Cleanup Complete! ==="
