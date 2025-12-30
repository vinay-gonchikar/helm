#!/bin/bash

# Uninstall script for all microservices
# Usage: ./undeploy-all.sh <namespace>
# Example: ./undeploy-all.sh dev

set -e

NAMESPACE=$1

if [ -z "$NAMESPACE" ]; then
    echo "Usage: $0 <namespace>"
    echo "Example: $0 dev"
    exit 1
fi

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${RED}========================================${NC}"
echo -e "${RED}Undeploying Microservices from $NAMESPACE${NC}"
echo -e "${RED}========================================${NC}"

# Array of services
SERVICES=("auth-service" "user-service" "order-service" "payment-service" "notification-service")

# Uninstall each service
for SERVICE in "${SERVICES[@]}"; do
    echo -e "\n${YELLOW}Uninstalling $SERVICE...${NC}"

    if helm status $SERVICE -n $NAMESPACE >/dev/null 2>&1; then
        helm uninstall $SERVICE --namespace $NAMESPACE
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ $SERVICE uninstalled successfully${NC}"
        else
            echo -e "${RED}✗ Failed to uninstall $SERVICE${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ $SERVICE not found, skipping...${NC}"
    fi
done

echo -e "\n${YELLOW}Do you want to delete the namespace $NAMESPACE? (y/n)${NC}"
read -r response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    kubectl delete namespace $NAMESPACE
    echo -e "${GREEN}✓ Namespace $NAMESPACE deleted${NC}"
else
    echo -e "${YELLOW}Namespace $NAMESPACE preserved${NC}"
fi

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}Undeployment completed!${NC}"
echo -e "${GREEN}========================================${NC}"
