# Microservices Helm Charts - Project Overview

## Summary

This project contains production-ready Helm charts for 5 microservices designed to run across 3 environments (dev, pre-prod, production) with dev and pre-prod sharing a cluster.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   Shared Cluster (Dev + Pre-Prod)           │
├──────────────────────────┬──────────────────────────────────┤
│  Namespace: dev          │  Namespace: pre-prod             │
│  Node Label: env=dev     │  Node Label: env=preprod         │
│                          │                                  │
│  • auth-service (1 pod)  │  • auth-service (2 pods)         │
│  • user-service (1 pod)  │  • user-service (2 pods)         │
│  • order-service (1 pod) │  • order-service (2 pods)        │
│  • payment-service (1)   │  • payment-service (2 pods)      │
│  • notification (1 pod)  │  • notification (2 pods)         │
└──────────────────────────┴──────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                   Production Cluster                         │
├─────────────────────────────────────────────────────────────┤
│  Namespace: production                                       │
│  Node Labels: env=production, node-type=high-performance     │
│                                                              │
│  • auth-service (3+ pods, HPA enabled)                       │
│  • user-service (3+ pods, HPA enabled)                       │
│  • order-service (3+ pods, HPA enabled)                      │
│  • payment-service (3+ pods, HPA enabled)                    │
│  • notification-service (3+ pods, HPA enabled)               │
└─────────────────────────────────────────────────────────────┘
```

## Microservices

| Service | Port | Purpose | Key Dependencies |
|---------|------|---------|------------------|
| auth-service | 8080 | Authentication & Authorization | PostgreSQL, JWT |
| user-service | 8081 | User Management | PostgreSQL, Redis |
| order-service | 8082 | Order Processing | PostgreSQL, Kafka |
| payment-service | 8083 | Payment Processing | PostgreSQL, Stripe |
| notification-service | 8084 | Notifications (Email/SMS) | PostgreSQL, SendGrid, Twilio |

## Environments

### Development
- **Purpose**: Active development and testing
- **Cluster**: Shared with pre-prod
- **Replicas**: 1 per service
- **Resources**: Minimal (100-200m CPU, 128-256Mi RAM)
- **Autoscaling**: Disabled
- **Logging**: Debug level
- **Domains**: `*-dev.example.com`

### Pre-Production
- **Purpose**: Staging and final testing before production
- **Cluster**: Shared with dev
- **Replicas**: 2 per service
- **Resources**: Medium (200-600m CPU, 192-768Mi RAM)
- **Autoscaling**: Optional
- **Logging**: Info level
- **Domains**: `*-preprod.example.com`

### Production
- **Purpose**: Live production workloads
- **Cluster**: Dedicated
- **Replicas**: 3+ per service with HPA
- **Resources**: High (500-2000m CPU, 512Mi-2Gi RAM)
- **Autoscaling**: Enabled
- **Logging**: Warn/Error level
- **High Availability**: Pod anti-affinity rules
- **Domains**: `*.example.com`

## Kubernetes Resources Per Service

Each microservice includes:

1. **Deployment** (`deployment.yaml`)
   - Rolling update strategy
   - Health checks (liveness & readiness)
   - Resource limits and requests
   - Volume mounts for persistent storage

2. **Service** (`service.yaml`)
   - ClusterIP type for internal communication
   - Port mapping

3. **Ingress** (`ingress.yaml`)
   - External access with HTTPS
   - TLS/SSL certificates via cert-manager
   - Rate limiting (production)

4. **ConfigMap** (`configmap.yaml`)
   - Non-sensitive configuration
   - Environment variables
   - Application settings

5. **Secret** (`secret.yaml`)
   - Sensitive data (base64 encoded)
   - Database credentials
   - API keys
   - Encryption keys

6. **PersistentVolumeClaim** (`pvc.yaml`)
   - Persistent storage
   - Configurable storage class and size
   - ReadWriteOnce access mode

7. **ServiceAccount** (`serviceaccount.yaml`)
   - Pod identity for RBAC

## File Structure

```
microservices-helm/
├── README.md                        # Main documentation
├── DEPLOYMENT-GUIDE.md              # Detailed deployment instructions
├── OVERVIEW.md                      # This file
├── deploy-all.sh                    # Bash deployment script
├── deploy-all.ps1                   # PowerShell deployment script
├── undeploy-all.sh                  # Uninstall script
│
├── auth-service/
│   ├── Chart.yaml                   # Chart metadata
│   ├── values.yaml                  # Default values
│   ├── templates/
│   │   ├── _helpers.tpl             # Template helpers
│   │   ├── deployment.yaml          # Deployment manifest
│   │   ├── service.yaml             # Service manifest
│   │   ├── ingress.yaml             # Ingress manifest
│   │   ├── configmap.yaml           # ConfigMap manifest
│   │   ├── secret.yaml              # Secret manifest
│   │   ├── pvc.yaml                 # PVC manifest
│   │   └── serviceaccount.yaml      # ServiceAccount manifest
│   └── environments/
│       ├── values-dev.yaml          # Dev environment values
│       ├── values-pre-prod.yaml     # Pre-prod environment values
│       └── values-prod.yaml         # Production environment values
│
├── user-service/                    # Same structure
├── order-service/                   # Same structure
├── payment-service/                 # Same structure
└── notification-service/            # Same structure
```

## Key Features

### 1. Environment Isolation
- Separate namespaces per environment
- Node selectors and tolerations
- Environment-specific resource allocation
- Different replica counts per environment

### 2. High Availability (Production)
- Multiple replicas (3+)
- Horizontal Pod Autoscaling (HPA)
- Pod anti-affinity rules
- Rolling updates with zero downtime

### 3. Security
- Base64 encoded secrets
- TLS/SSL via cert-manager
- Service account per microservice
- Network policies ready
- Non-root containers

### 4. Storage
- Persistent storage per service
- Environment-specific storage classes
- Configurable sizes
- Backup-friendly PVCs

### 5. Observability
- Health check endpoints (`/health`, `/ready`)
- Structured logging
- Prometheus-ready metrics endpoints
- Configurable log levels per environment

### 6. Scalability
- Horizontal Pod Autoscaling
- Resource limits and requests
- CPU and memory-based scaling
- Environment-specific scaling policies

## Quick Start Commands

### Deploy Everything to Dev
```bash
./deploy-all.sh dev dev
```

### Deploy Everything to Pre-Prod
```bash
./deploy-all.sh pre-prod pre-prod
```

### Deploy Everything to Production
```bash
./deploy-all.sh prod production
```

### Deploy Single Service
```bash
helm install auth-service ./auth-service \
  --namespace dev \
  --values ./auth-service/environments/values-dev.yaml
```

### Upgrade Service
```bash
helm upgrade auth-service ./auth-service \
  --namespace production \
  --values ./auth-service/environments/values-prod.yaml \
  --set image.tag=v2.0.0
```

### Rollback
```bash
helm rollback auth-service -n production
```

### Uninstall Everything
```bash
./undeploy-all.sh dev
```

## Configuration Management

### Image Configuration
Update in `environments/values-<env>.yaml`:
```yaml
image:
  repository: your-registry/service-name
  tag: "v1.0.0"
```

### Resource Tuning
Adjust resources per environment:
```yaml
resources:
  limits:
    cpu: 1000m
    memory: 1Gi
  requests:
    cpu: 500m
    memory: 512Mi
```

### Secrets Management
Base64 encode and update:
```bash
echo -n "secret-value" | base64
# Add to values-<env>.yaml
```

### Storage Configuration
```yaml
storage:
  storageClassName: "fast-ssd"
  size: 10Gi
  mountPath: /data
```

## Monitoring & Alerts

### Health Endpoints
- Liveness: `GET /health` - Restart pod if fails
- Readiness: `GET /ready` - Remove from service if fails

### Metrics
Configure Prometheus scraping on service port.

### Log Aggregation
All services log to stdout/stderr for collection by:
- ELK Stack
- Fluentd/Fluent Bit
- Cloud-native solutions (CloudWatch, Stackdriver)

## Networking

### Internal Communication
Services communicate via ClusterIP services:
```
http://auth-service:8080
http://user-service:8081
http://order-service:8082
http://payment-service:8083
http://notification-service:8084
```

### External Access
Via Ingress with TLS:
```
https://auth.example.com
https://user.example.com
https://order.example.com
https://payment.example.com
https://notification.example.com
```

## Cluster Requirements

### Shared Cluster (Dev + Pre-Prod)
- **Minimum Nodes**: 4 (2 for dev, 2 for pre-prod)
- **Node Resources**: 4 CPU, 8Gi RAM per node
- **Total**: ~16 CPU, 32Gi RAM

### Production Cluster
- **Minimum Nodes**: 3 (high-availability)
- **Node Resources**: 8 CPU, 16Gi RAM per node
- **Total**: ~24 CPU, 48Gi RAM
- **Recommended**: 5+ nodes for better distribution

### Prerequisites
- Kubernetes 1.23+
- Helm 3.x
- Ingress Controller (nginx)
- cert-manager
- Storage provisioner
- Metrics server (for HPA)

## Customization

### Adding a New Service
1. Copy existing service directory
2. Update Chart.yaml with new service name
3. Update _helpers.tpl references
4. Customize values.yaml
5. Create environment-specific values
6. Add to deployment scripts

### Modifying Resources
Edit `environments/values-<env>.yaml` for environment-specific changes.

### Adding New Environments
1. Create `values-<new-env>.yaml`
2. Configure resources and replicas
3. Update deployment scripts
4. Label nodes appropriately

## Maintenance

### Regular Tasks
- Update image tags for deployments
- Rotate secrets monthly
- Review and adjust resource limits
- Monitor HPA behavior
- Update Helm charts

### Backup Strategy
- PVC snapshots (storage provider)
- Helm values in version control
- Database backups (external to Helm)
- Configuration backups

## Troubleshooting

### Common Issues
1. **ImagePullBackOff**: Check image repository and credentials
2. **CrashLoopBackOff**: Check application logs and health endpoints
3. **Pending Pods**: Check resource quotas and node selectors
4. **Service Unavailable**: Check endpoints and pod readiness

### Debug Commands
```bash
kubectl get pods -n <namespace>
kubectl describe pod <pod-name> -n <namespace>
kubectl logs -f deployment/<service> -n <namespace>
kubectl get events -n <namespace> --sort-by='.lastTimestamp'
```

## Security Best Practices

1. Rotate secrets regularly
2. Use image pull secrets for private registries
3. Enable network policies
4. Use Pod Security Standards
5. Run containers as non-root
6. Scan images for vulnerabilities
7. Use TLS for all external traffic
8. Implement RBAC properly

## Performance Optimization

1. Set appropriate resource limits
2. Enable HPA for production
3. Use pod anti-affinity for critical services
4. Choose fast storage classes for databases
5. Implement caching strategies
6. Monitor and adjust based on metrics

## Cost Optimization

1. Right-size resources per environment
2. Use node selectors efficiently
3. Enable cluster autoscaling
4. Consider spot instances for dev/test
5. Implement resource quotas
6. Monitor unused resources

## Support & Documentation

- **Main Documentation**: [README.md](./README.md)
- **Deployment Guide**: [DEPLOYMENT-GUIDE.md](./DEPLOYMENT-GUIDE.md)
- **This Overview**: [OVERVIEW.md](./OVERVIEW.md)

## Version History

- **v1.0.0** (2025-12-30): Initial release
  - 5 microservices
  - 3 environments
  - Full Kubernetes resource support
  - Automated deployment scripts

## License

MIT License

## Contributing

When contributing:
1. Test changes in dev environment first
2. Update documentation
3. Follow existing patterns
4. Update version numbers
5. Create meaningful commit messages
