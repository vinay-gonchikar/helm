#!/bin/bash

# Deployment script for all microservices
# Usage: ./deploy-all.sh <environment> <namespace>
# Example: ./deploy-all.sh dev dev

set -e

ENVIRONMENT=$1
NAMESPACE=$2

if [ -z "$ENVIRONMENT" ] || [ -z "$NAMESPACE" ]; then
    echo "Usage: $0 <environment> <namespace>"
    echo "Environments: dev, pre-prod, prod"
    echo "Example: $0 dev dev"
    exit 1
fi

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|pre-prod|prod)$ ]]; then
    echo "Error: Environment must be one of: dev, pre-prod, prod"
    exit 1
fi

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Deploying Microservices to $ENVIRONMENT${NC}"
echo -e "${GREEN}========================================${NC}"

# Create namespace if it doesn't exist
echo -e "\n${YELLOW}Creating namespace: $NAMESPACE${NC}"
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Array of services
SERVICES=("auth-service" "user-service" "order-service" "payment-service" "notification-service")

# Deploy each service
for SERVICE in "${SERVICES[@]}"; do
    echo -e "\n${YELLOW}Deploying $SERVICE...${NC}"

    if helm status $SERVICE -n $NAMESPACE >/dev/null 2>&1; then
        echo -e "${YELLOW}Upgrading existing release...${NC}"
        helm upgrade $SERVICE ./$SERVICE \
            --namespace $NAMESPACE \
            --values ./$SERVICE/environments/values-$ENVIRONMENT.yaml \
            --wait \
            --timeout 5m
    else
        echo -e "${YELLOW}Installing new release...${NC}"
        helm install $SERVICE ./$SERVICE \
            --namespace $NAMESPACE \
            --values ./$SERVICE/environments/values-$ENVIRONMENT.yaml \
            --wait \
            --timeout 5m
    fi

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $SERVICE deployed successfully${NC}"
    else
        echo -e "${RED}✗ Failed to deploy $SERVICE${NC}"
        exit 1
    fi
done

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment Summary${NC}"
echo -e "${GREEN}========================================${NC}"

# Show deployment status
echo -e "\n${YELLOW}Deployment Status:${NC}"
kubectl get deployments -n $NAMESPACE

echo -e "\n${YELLOW}Pod Status:${NC}"
kubectl get pods -n $NAMESPACE

echo -e "\n${YELLOW}Service Status:${NC}"
kubectl get services -n $NAMESPACE

echo -e "\n${YELLOW}Ingress Status:${NC}"
kubectl get ingress -n $NAMESPACE

echo -e "\n${YELLOW}PVC Status:${NC}"
kubectl get pvc -n $NAMESPACE

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}All services deployed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
