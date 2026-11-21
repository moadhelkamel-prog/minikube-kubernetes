Clear-Host
Write-Host "=== Etape 2 - Recuperation du projet et analyse ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "[2.1] Clone du depot" -ForegroundColor Yellow
if (Test-Path "C:\Users\kmoua\Documents\Default Project\cursus-devops") {
    Write-Host "Depot deja clone dans cursus-devops\" -ForegroundColor Green
} else {
    git clone https://github.com/diranetafen/cursus-devops.git
}
Write-Host ""
Write-Host "[2.2] Contenu du dossier minikube_ubuntu22" -ForegroundColor Yellow
Set-Location "C:\Users\kmoua\Documents\Default Project\cursus-devops\vagrant\minikube\minikube_ubuntu22"
Get-ChildItem
Write-Host ""
Write-Host "[2.3] Vagrantfile" -ForegroundColor Yellow
Get-Content Vagrantfile
Write-Host ""
Write-Host "[2.4] install_minikube.sh (extrait)" -ForegroundColor Yellow
Select-String -Path install_minikube.sh -Pattern "minikube start|docker-ce=|kubelet kubeadm|cri-dockerd|MINIKUBE_VERSION" | Select-Object -First 8 | ForEach-Object { $_.Line }