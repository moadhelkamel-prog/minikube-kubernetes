Clear-Host
Write-Host "=== Etape 4 - Minikube sur Docker dans WSL2 ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "[4.1] Versions installees dans WSL2" -ForegroundColor Yellow
wsl -d Ubuntu -u root -e bash -c "docker --version; minikube version; kubectl version --client 2>/dev/null | head -2"
Write-Host ""
Write-Host "[4.2] Demarrage du cluster (deja fait, reprise)" -ForegroundColor Yellow
wsl -d Ubuntu -u root -e su - moadh -c "minikube start --driver=docker --memory=3000 --cpus=2 2>&1 | tail -6"
Write-Host ""
Write-Host "[4.3] minikube status" -ForegroundColor Yellow
wsl -d Ubuntu -u root -e su - moadh -c "minikube status"