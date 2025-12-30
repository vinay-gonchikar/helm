# Deployment Guide for Microservices

## Quick Start

### Deploy All Services to Development
```bash
# Linux/Mac
./deploy-all.sh dev dev

# Windows PowerShell
.\deploy-all.ps1 -Environment dev -Namespace dev
```

### Deploy All Services to Pre-Production
```bash
# Linux/Mac
./deploy-all.sh pre-prod pre-prod

# Windows PowerShell
.\deploy-all.ps1 -Environment pre-prod -Namespace pre-prod
```

### Deploy All Services to Production
```bash
# Linux/Mac
./deploy-all.sh prod production

# Windows PowerShell
.\deploy-all.ps1 -Environment prod -Namespace production
```

## Individual Service Deployment

### Deploy Single Service

#### Development
```bash
helm install auth-service ./auth-service \
  --namespace dev \
  --values ./auth-service/environments/values-dev.yaml \
  --create-namespace
```

#### Pre-Production
```bash
helm install auth-service ./auth-service \
  --namespace pre-prod \
  --values ./auth-service/environments/values-pre-prod.yaml \
  --create-namespace
```

#### Production
```bash
helm install auth-service ./auth-service \
  --namespace production \
  --values ./auth-service/environments/values-prod.yaml \
  --create-namespace
```

## Upgrade Strategy

### Zero-Downtime Upgrade
```bash
helm upgrade auth-service ./auth-service \
  --namespace production \
  --values ./auth-service/environments/values-prod.yaml \
  --set image.tag=v2.0.0 \
  --wait \
  --timeout 10m
```

### Rollback if Needed
```bash
# List releases
helm history auth-service -n production

# Rollback to previous version
helm rollback auth-service -n production

# Rollback to specific revision
helm rollback auth-service 2 -n production
```

## Environment-Specific Configuration

### Development Environment
- **Cluster**: Shared with pre-prod
- **Namespace**: `dev`
- **Replicas**: 1
- **Resources**: Low (100m CPU, 128Mi RAM)
- **Logging**: Debug level
- **Autoscaling**: Disabled
- **Node Selector**: `environment: dev`

### Pre-Production Environment
- **Cluster**: Shared with dev
- **Namespace**: `pre-prod`
- **Replicas**: 2
- **Resources**: Medium (200m CPU, 192Mi RAM)
- **Logging**: Info level
- **Autoscaling**: Optional
- **Node Selector**: `environment: preprod`

### Production Environment
- **Cluster**: Dedicated
- **Namespace**: `production`
- **Replicas**: 3+
- **Resources**: High (500m+ CPU, 512Mi+ RAM)
- **Logging**: Warn/Error level
- **Autoscaling**: Enabled
- **Node Selector**: `environment: production, node-type: high-performance`
- **Anti-Affinity**: Enabled for critical services

## Pre-Deployment Checklist

### Before Deploying to Any Environment

1. **Update Image Tags**
   ```yaml
   # In values-<env>.yaml
   image:
     tag: "v1.2.3"  # Update to your version
   ```

2. **Update Secrets**
   ```bash
   # Generate base64 encoded secrets
   echo -n "your-secret" | base64

   # Update in values-<env>.yaml
   secrets:
     data:
       DATABASE_URL: "<base64-encoded-value>"
   ```

3. **Update Ingress Hosts**
   ```yaml
   ingress:
     hosts:
       - host: service.yourdomain.com  # Update
   ```

4. **Verify Storage Class**
   ```bash
   kubectl get storageclass

   # Update in values
   storage:
     storageClassName: "your-storage-class"
   ```

5. **Check Resource Quotas**
   ```bash
   kubectl describe quota -n <namespace>
   ```

### Production-Specific Checklist

- [ ] All secrets rotated and updated
- [ ] TLS certificates configured
- [ ] Monitoring and alerting setup
- [ ] Backup strategy in place
- [ ] Disaster recovery plan documented
- [ ] Load testing completed
- [ ] Security scan passed
- [ ] Database migrations tested
- [ ] Rollback plan ready

## Cluster Setup

### Shared Cluster (Dev + Pre-Prod)

#### Label Nodes
```bash
# Dev nodes
kubectl label nodes node-1 environment=dev
kubectl label nodes node-2 environment=dev

# Pre-prod nodes
kubectl label nodes node-3 environment=preprod
kubectl label nodes node-4 environment=preprod
```

#### Taint Nodes (Optional)
```bash
# Dev nodes
kubectl taint nodes node-1 environment=dev:NoSchedule
kubectl taint nodes node-2 environment=dev:NoSchedule

# Pre-prod nodes
kubectl taint nodes node-3 environment=preprod:NoSchedule
kubectl taint nodes node-4 environment=preprod:NoSchedule
```

### Production Cluster

#### Label Nodes
```bash
kubectl label nodes node-prod-1 environment=production
kubectl label nodes node-prod-1 node-type=high-performance

kubectl label nodes node-prod-2 environment=production
kubectl label nodes node-prod-2 node-type=high-performance

kubectl label nodes node-prod-3 environment=production
kubectl label nodes node-prod-3 node-type=high-performance
```

#### Taint Nodes
```bash
kubectl taint nodes node-prod-1 environment=production:NoSchedule
kubectl taint nodes node-prod-2 environment=production:NoSchedule
kubectl taint nodes node-prod-3 environment=production:NoSchedule
```

## Post-Deployment Verification

### Check All Resources
```bash
# Check deployments
kubectl get deployments -n <namespace>

# Check pods
kubectl get pods -n <namespace> -o wide

# Check services
kubectl get services -n <namespace>

# Check ingress
kubectl get ingress -n <namespace>

# Check PVCs
kubectl get pvc -n <namespace>

# Check secrets
kubectl get secrets -n <namespace>

# Check configmaps
kubectl get configmap -n <namespace>
```

### Test Service Endpoints
```bash
# Test internal service
kubectl run curl-test --image=curlimages/curl -i --rm --restart=Never \
  -n <namespace> -- curl -s http://auth-service:8080/health

# Test external ingress
curl -k https://auth.yourdomain.com/health
```

### Check Logs
```bash
# View logs
kubectl logs -f deployment/auth-service -n <namespace>

# View logs from all pods
kubectl logs -f deployment/auth-service -n <namespace> --all-containers=true

# View previous logs (if pod crashed)
kubectl logs deployment/auth-service -n <namespace> --previous
```

### Monitor Resources
```bash
# CPU and Memory usage
kubectl top pods -n <namespace>
kubectl top nodes

# Describe deployment
kubectl describe deployment auth-service -n <namespace>

# Get events
kubectl get events -n <namespace> --sort-by='.lastTimestamp'
```

## Troubleshooting

### Pod Not Starting

#### Check Pod Status
```bash
kubectl get pods -n <namespace>
kubectl describe pod <pod-name> -n <namespace>
```

#### Common Issues
1. **ImagePullBackOff**: Check image name and pull secrets
2. **CrashLoopBackOff**: Check application logs
3. **Pending**: Check resource quotas and node selectors
4. **OOMKilled**: Increase memory limits

### Service Not Accessible

```bash
# Check service endpoints
kubectl get endpoints auth-service -n <namespace>

# Check service
kubectl describe service auth-service -n <namespace>

# Port forward for testing
kubectl port-forward service/auth-service 8080:8080 -n <namespace>
```

### Ingress Not Working

```bash
# Check ingress
kubectl describe ingress auth-service -n <namespace>

# Check ingress controller logs
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller

# Verify DNS
nslookup auth.yourdomain.com
```

### PVC Issues

```bash
# Check PVC status
kubectl get pvc -n <namespace>

# Describe PVC
kubectl describe pvc auth-service-pvc -n <namespace>

# Check storage class
kubectl get storageclass

# Check PV
kubectl get pv
```

## Monitoring and Observability

### Health Checks
All services expose:
- **Liveness**: `/health` - Pod restart if fails
- **Readiness**: `/ready` - Remove from service if fails

### Metrics Endpoints
Configure Prometheus scraping:
```yaml
# Add to service annotations
annotations:
  prometheus.io/scrape: "true"
  prometheus.io/port: "8080"
  prometheus.io/path: "/metrics"
```

### Log Aggregation
Services log to stdout/stderr for collection by:
- Fluentd/Fluent Bit
- Filebeat
- CloudWatch/Stackdriver

## Scaling

### Manual Scaling
```bash
# Scale deployment
kubectl scale deployment auth-service --replicas=5 -n production
```

### Horizontal Pod Autoscaling
HPA is configured in production values:
```yaml
autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
```

Check HPA status:
```bash
kubectl get hpa -n production
kubectl describe hpa auth-service -n production
```

## Backup and Restore

### Backup PVCs
```bash
# Create snapshot (depends on storage provider)
kubectl get pvc -n production
# Use your storage provider's snapshot functionality
```

### Backup Helm Values
```bash
# Save current values
helm get values auth-service -n production > backup-values.yaml
```

### Restore
```bash
# Restore from backup values
helm upgrade auth-service ./auth-service \
  --namespace production \
  --values backup-values.yaml
```

## Security

### Update Secrets
```bash
# Create new secret
kubectl create secret generic auth-service-secret \
  --from-literal=DATABASE_URL="new-connection-string" \
  --dry-run=client -o yaml | kubectl apply -n production -f -

# Restart pods to pick up new secrets
kubectl rollout restart deployment auth-service -n production
```

### Network Policies
Implement network policies to restrict traffic:
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: auth-service-netpol
spec:
  podSelector:
    matchLabels:
      app: auth-service
  policyTypes:
  - Ingress
  - Egress
```

## Maintenance Windows

### Drain Node for Maintenance
```bash
# Cordon node (prevent new pods)
kubectl cordon node-1

# Drain node (evict pods)
kubectl drain node-1 --ignore-daemonsets --delete-emptydir-data

# Perform maintenance...

# Uncordon node
kubectl uncordon node-1
```

### Update Strategy
Use rolling updates (configured by default):
```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxUnavailable: 1
    maxSurge: 1
```

## Disaster Recovery

### Full Cluster Failure
1. Provision new cluster
2. Restore from backups
3. Deploy using Helm charts
4. Update DNS/ingress
5. Verify all services

### Data Loss Prevention
- Regular PVC snapshots
- Database backups
- Config in version control
- Helm values backed up

## CI/CD Integration

### GitLab CI Example
```yaml
deploy:production:
  stage: deploy
  script:
    - helm upgrade --install auth-service ./auth-service
        --namespace production
        --values ./auth-service/environments/values-prod.yaml
        --set image.tag=$CI_COMMIT_SHA
  only:
    - main
```

### GitHub Actions Example
```yaml
- name: Deploy to Production
  run: |
    helm upgrade --install auth-service ./auth-service \
      --namespace production \
      --values ./auth-service/environments/values-prod.yaml \
      --set image.tag=${{ github.sha }}
```

## Support Contacts

- **Infrastructure**: infrastructure@example.com
- **Development**: dev-team@example.com
- **Security**: security@example.com
- **On-Call**: oncall@example.com
