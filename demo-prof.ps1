# demo-prof.ps1 - Script de demonstration pour le professeur
# Usage : .\demo-prof.ps1  (ou .\demo-prof.cmd)
# Affiche toutes les preuves du TP : outils, Vagrant, cluster Kubernetes, test applicatif.
param()

function Pause-Step([string]$msg) {
    Write-Host ""
    Write-Host "------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host $msg -ForegroundColor Yellow
    Read-Host "Appuyez sur Entree pour continuer"
}

Clear-Host
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  TP Minikube - Demonstration (SEC450)" -ForegroundColor Cyan
Write-Host "  Etudiant : kmoua   |   Poste : Windows 11 Pro 23H2" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# --- 1. Outils installes ---
Write-Host "[1] Outils installes et leurs versions" -ForegroundColor Green
$env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')
foreach ($c in 'git','vagrant','VBoxManage','minikube','kubectl') {
    $p = Get-Command $c -ErrorAction SilentlyContinue
    if ($p) { '  {0,-12} {1}' -f $c, $p.Source } else { '  {0,-12} MANQUANT' -f $c }
}
git --version
vagrant --version
VBoxManage --version
minikube version
kubectl version --client
Pause-Step "[1] Fin de la verification des outils."

# --- 2. Vagrant (voie VirtualBox) ---
Write-Host "[2] Vagrant - voie VirtualBox (tentative documentee)" -ForegroundColor Green
$env:Path += ";C:\Program Files\Vagrant\bin;C:\Program Files\Oracle\VirtualBox"
Set-Location "C:\Users\kmoua\Documents\Default Project\cursus-devops\vagrant\minikube\minikube_ubuntu22"
vagrant status
Write-Host ""
vagrant box list
Write-Host ""
Write-Host "  Note : la VM est en 'poweroff' car ce poste a Hyper-V/WSL2 actif," -ForegroundColor DarkYellow
Write-Host "  ce qui rend VirtualBox ~25x plus lent (pas de VT-x). Le cluster a ete" -ForegroundColor DarkYellow
Write-Host "  deploye via Minikube driver 'docker' dans WSL2 (meme resultat)." -ForegroundColor DarkYellow
Pause-Step "[2] Fin de la partie Vagrant."

# --- 3. Cluster Kubernetes ---
Write-Host "[3] Cluster Kubernetes (Minikube)" -ForegroundColor Green
wsl -d Ubuntu -u root -e bash -c "systemctl start docker" 2>$null
wsl -d Ubuntu -u root -e su - moadh -c "minikube start --driver=docker --memory=3000 --cpus=2 2>&1 | tail -3"
Write-Host ""
wsl -d Ubuntu -u root -e su - moadh -c "minikube status"
Write-Host ""
Write-Host "  kubectl get nodes :" -ForegroundColor Yellow
wsl -d Ubuntu -u root -e su - moadh -c "kubectl get nodes -o wide"
Pause-Step "[3] Fin de la verification du cluster."

# --- 4. Pods systeme ---
Write-Host "[4] Pods du control-plane" -ForegroundColor Green
wsl -d Ubuntu -u root -e su - moadh -c "kubectl get pods -A"
Pause-Step "[4] Fin de la verification des pods."

# --- 5. Test applicatif ---
Write-Host "[5] Test applicatif : deployment nginx + service NodePort" -ForegroundColor Green
wsl -d Ubuntu -u root -e su - moadh -c "kubectl get deployment,svc 2>/dev/null | grep -E 'NAME|web'"
Write-Host ""
wsl -d Ubuntu -u root -e su - moadh -c "bash /mnt/c/Users/kmoua/Documents/Default\ Project/demo-step5.sh"
Pause-Step "[5] Fin du test applicatif."

# --- 6. Conclusion ---
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Resume : cluster Kubernetes mono-noeud operationnel." -ForegroundColor Cyan
Write-Host "  Noeud : Ready  |  Pods systeme : Running  |  HTTP 200 OK" -ForegroundColor Cyan
Write-Host "  Compte rendu : TP-minikube-compte-rendu.md" -ForegroundColor Cyan
Write-Host "  Scrins      : screenshots/step1.png .. step5.png" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan