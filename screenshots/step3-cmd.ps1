Clear-Host
Write-Host "=== Etape 3 - vagrant up (voie VirtualBox) et blocage ===" -ForegroundColor Cyan
$env:Path += ";C:\Program Files\Vagrant\bin;C:\Program Files\Oracle\VirtualBox"
Set-Location "C:\Users\kmoua\Documents\Default Project\cursus-devops\vagrant\minikube\minikube_ubuntu22"
Write-Host ""
Write-Host "[3.1] Etat de la VM" -ForegroundColor Yellow
vagrant status
Write-Host ""
Write-Host "[3.2] Box telechargee" -ForegroundColor Yellow
vagrant box list
Write-Host ""
Write-Host "[3.3] Historique des tentatives (resume)" -ForegroundColor Yellow
Write-Host "- minikube start --driver=virtualbox : This computer doesn't have VT-X/AMD-v enabled" -ForegroundColor Red
Write-Host "- vagrant up : conflicting host only adapter with DHCP enabled (resolu)" -ForegroundColor Red
Write-Host "- vagrant up : Timed out while waiting for the machine to boot (~25x plus lent)" -ForegroundColor Red
Write-Host ""
Write-Host "Cause : Hyper-V/WSL2 actif -> VirtualBox n'a pas VT-x, utilise NEM/WHPX." -ForegroundColor DarkYellow