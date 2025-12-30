# PowerShell Deployment script for all microservices
# Usage: .\deploy-all.ps1 -Environment <env> -Namespace <ns>
# Example: .\deploy-all.ps1 -Environment dev -Namespace dev

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("dev", "pre-prod", "prod")]
    [string]$Environment,

    [Parameter(Mandatory=$true)]
    [string]$Namespace
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Green
Write-Host "Deploying Microservices to $Environment" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

# Create namespace if it doesn't exist
Write-Host "`nCreating namespace: $Namespace" -ForegroundColor Yellow
kubectl create namespace $Namespace --dry-run=client -o yaml | kubectl apply -f -

# Array of services
$services = @("auth-service", "user-service", "order-service", "payment-service", "notification-service")

# Deploy each service
foreach ($service in $services) {
    Write-Host "`nDeploying $service..." -ForegroundColor Yellow

    # Check if release exists
    $releaseExists = $false
    try {
        helm status $service -n $Namespace 2>&1 | Out-Null
        $releaseExists = $true
    } catch {
        $releaseExists = $false
    }

    if ($releaseExists) {
        Write-Host "Upgrading existing release..." -ForegroundColor Yellow
        helm upgrade $service "./$service" `
            --namespace $Namespace `
            --values "./$service/environments/values-$Environment.yaml" `
            --wait `
            --timeout 5m
    } else {
        Write-Host "Installing new release..." -ForegroundColor Yellow
        helm install $service "./$service" `
            --namespace $Namespace `
            --values "./$service/environments/values-$Environment.yaml" `
            --wait `
            --timeout 5m
    }

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ $service deployed successfully" -ForegroundColor Green
    } else {
        Write-Host "✗ Failed to deploy $service" -ForegroundColor Red
        exit 1
    }
}

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "Deployment Summary" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

# Show deployment status
Write-Host "`nDeployment Status:" -ForegroundColor Yellow
kubectl get deployments -n $Namespace

Write-Host "`nPod Status:" -ForegroundColor Yellow
kubectl get pods -n $Namespace

Write-Host "`nService Status:" -ForegroundColor Yellow
kubectl get services -n $Namespace

Write-Host "`nIngress Status:" -ForegroundColor Yellow
kubectl get ingress -n $Namespace

Write-Host "`nPVC Status:" -ForegroundColor Yellow
kubectl get pvc -n $Namespace

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "All services deployed successfully!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
