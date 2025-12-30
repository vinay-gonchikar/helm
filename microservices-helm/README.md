# Microservices Helm Charts

This repository contains Helm charts for 5 microservices designed to run across 3 environments: Development (dev), Pre-Production (pre-prod), and Production (prod).

## Architecture Overview

### Microservices
1. **auth-service** - Authentication and authorization (Port: 8080)
2. **user-service** - User management (Port: 8081)
3. **order-service** - Order processing (Port: 8082)
4. **payment-service** - Payment processing (Port: 8083)
5. **notification-service** - Notifications (Email/SMS) (Port: 8084)

### Environments
- **Development (dev)** - Shared cluster with pre-prod
- **Pre-Production (pre-prod)** - Shared cluster with dev
- **Production (prod)** - Dedicated production cluster

### Cluster Configuration
- **Shared Cluster**: Hosts both dev and pre-prod environments using namespace and node selector separation
- **Production Cluster**: Dedicated cluster for production workloads

## Directory Structure

```
microservices-helm/
├── auth-service/
│   ├── Chart.yaml
│   ├── values.yaml
│   ├── templates/
│   │   ├── _helpers.tpl
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   ├── ingress.yaml
│   │   ├── configmap.yaml
│   │   ├── secret.yaml
│   │   ├── pvc.yaml
│   │   └── serviceaccount.yaml
│   └── environments/
│       ├── values-dev.yaml
│       ├── values-pre-prod.yaml
│       └── values-prod.yaml
├── user-service/
├── order-service/
├── payment-service/
└── notification-service/
```

## Kubernetes Resources Included

Each microservice includes:
- **Deployment**: Container orchestration with health checks
- **Service**: ClusterIP service for internal communication
- **Ingress**: External access with TLS/SSL
- **ConfigMap**: Non-sensitive configuration
- **Secret**: Sensitive data (base64 encoded)
- **PersistentVolumeClaim (PVC)**: Persistent storage
- **ServiceAccount**: Pod identity

## Prerequisites

- Kubernetes cluster(s) (v1.23+)
- Helm 3.x installed
- kubectl configured
- Ingress controller (nginx recommended)
- cert-manager for TLS certificates
- Storage provisioner configured

## Installation

### Deploy to Development

```bash
# Create namespace
kubectl create namespace dev

# Deploy auth-service
helm install auth-service ./auth-service \
  --namespace dev \
  --values ./auth-service/environments/values-dev.yaml

# Deploy user-service
helm install user-service ./user-service \
  --namespace dev \
  --values ./user-service/environments/values-dev.yaml

# Deploy order-service
helm install order-service ./order-service \
  --namespace dev \
  --values ./order-service/environments/values-dev.yaml

# Deploy payment-service
helm install payment-service ./payment-service \
  --namespace dev \
  --values ./payment-service/environments/values-dev.yaml

# Deploy notification-service
helm install notification-service ./notification-service \
  --namespace dev \
  --values ./notification-service/environments/values-dev.yaml
```

### Deploy to Pre-Production

```bash
# Create namespace
kubectl create namespace pre-prod

# Deploy all services
helm install auth-service ./auth-service \
  --namespace pre-prod \
  --values ./auth-service/environments/values-pre-prod.yaml

helm install user-service ./user-service \
  --namespace pre-prod \
  --values ./user-service/environments/values-pre-prod.yaml

helm install order-service ./order-service \
  --namespace pre-prod \
  --values ./order-service/environments/values-pre-prod.yaml

helm install payment-service ./payment-service \
  --namespace pre-prod \
  --values ./payment-service/environments/values-pre-prod.yaml

helm install notification-service ./notification-service \
  --namespace pre-prod \
  --values ./notification-service/environments/values-pre-prod.yaml
```

### Deploy to Production

```bash
# Create namespace
kubectl create namespace production

# Deploy all services
helm install auth-service ./auth-service \
  --namespace production \
  --values ./auth-service/environments/values-prod.yaml

helm install user-service ./user-service \
  --namespace production \
  --values ./user-service/environments/values-prod.yaml

helm install order-service ./order-service \
  --namespace production \
  --values ./order-service/environments/values-prod.yaml

helm install payment-service ./payment-service \
  --namespace production \
  --values ./payment-service/environments/values-prod.yaml

helm install notification-service ./notification-service \
  --namespace production \
  --values ./notification-service/environments/values-prod.yaml
```

## Upgrade Deployments

```bash
# Upgrade a service in dev
helm upgrade auth-service ./auth-service \
  --namespace dev \
  --values ./auth-service/environments/values-dev.yaml

# Upgrade in production
helm upgrade auth-service ./auth-service \
  --namespace production \
  --values ./auth-service/environments/values-prod.yaml
```

## Uninstall

```bash
# Uninstall from dev
helm uninstall auth-service --namespace dev

# Uninstall from production
helm uninstall auth-service --namespace production
```

## Configuration

### Environment-Specific Settings

#### Development
- Lower resource limits
- Debug logging enabled
- Single replica
- Uses "standard" storage class
- Shared cluster with node selector

#### Pre-Production
- Medium resource limits
- Info logging
- 2 replicas
- Autoscaling disabled by default
- Shared cluster with node selector

#### Production
- High resource limits
- Warning/error logging only
- 3+ replicas
- Autoscaling enabled
- Pod anti-affinity for high availability
- Fast SSD storage class
- Rate limiting on ingress

### Secrets Management

All secrets are base64 encoded. Before deploying to production:

1. Update secrets in `environments/values-<env>.yaml`
2. Use external secret management (e.g., HashiCorp Vault, AWS Secrets Manager)
3. Rotate secrets regularly

Example to encode a secret:
```bash
echo -n "your-secret-value" | base64
```

### Ingress Configuration

Update the ingress hosts in environment values files:
```yaml
ingress:
  hosts:
    - host: auth.yourdomain.com  # Update this
```

### Storage Configuration

Adjust storage class and size based on your cluster:
```yaml
storage:
  storageClassName: "fast-ssd"  # Your storage class
  size: 10Gi
```

## Monitoring and Health Checks

Each service includes:
- **Liveness Probe**: `/health` endpoint
- **Readiness Probe**: `/ready` endpoint

Configure based on your application:
```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10
```

## Troubleshooting

### View pod status
```bash
kubectl get pods -n dev
kubectl get pods -n pre-prod
kubectl get pods -n production
```

### Check logs
```bash
kubectl logs -f deployment/auth-service -n dev
```

### Check service endpoints
```bash
kubectl get endpoints -n dev
```

### Describe resources
```bash
kubectl describe deployment auth-service -n dev
kubectl describe ingress auth-service -n dev
```

### Check PVC status
```bash
kubectl get pvc -n dev
```

## Cluster Setup Notes

### Shared Cluster (Dev + Pre-Prod)
Both environments use node selectors and tolerations to ensure proper pod placement:

```yaml
nodeSelector:
  environment: dev  # or preprod

tolerations:
  - key: "environment"
    operator: "Equal"
    value: "dev"
    effect: "NoSchedule"
```

Label your nodes accordingly:
```bash
kubectl label nodes <node-name> environment=dev
kubectl label nodes <node-name> environment=preprod
```

### Production Cluster
Production uses dedicated nodes with high-performance characteristics:

```bash
kubectl label nodes <node-name> environment=production
kubectl label nodes <node-name> node-type=high-performance
```

## CI/CD Integration

Example GitHub Actions workflow:

```yaml
- name: Deploy to Dev
  run: |
    helm upgrade --install auth-service ./auth-service \
      --namespace dev \
      --values ./auth-service/environments/values-dev.yaml \
      --set image.tag=${{ github.sha }}
```

## Security Best Practices

1. Use image pull secrets for private registries
2. Enable network policies
3. Use Pod Security Policies/Standards
4. Regularly update secrets
5. Enable TLS for all ingress
6. Use cert-manager for automated certificate management
7. Implement RBAC properly

## Customization

To customize for your needs:

1. Update image repositories in values files
2. Adjust resource limits based on your workload
3. Configure autoscaling thresholds
4. Set appropriate storage sizes
5. Update ingress hosts and TLS settings
6. Configure environment-specific secrets

## Support

For issues or questions:
- Check logs: `kubectl logs`
- Verify configurations: `helm get values <release-name> -n <namespace>`
- Validate templates: `helm template <chart-name> --debug`

## License

MIT License
