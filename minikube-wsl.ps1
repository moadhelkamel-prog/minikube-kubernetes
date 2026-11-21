# TP Minikube - helper (cluster dans WSL2 Ubuntu + Docker)
# Usage :
#   .\minikube-wsl.ps1 start     -> demarre Docker + Minikube et affiche les noeuds
#   .\minikube-wsl.ps1 status    -> etat du cluster + pods
#   .\minikube-wsl.ps1 kubectl   -> kubectl get nodes -o wide / pods -A / services
#   .\minikube-wsl.ps1 stop      -> arrete le cluster
param(
    [ValidateSet("start", "status", "kubectl", "stop")]
    [string]$Action = "start"
)

function Run-Bash([string]$cmd) {
    wsl -d Ubuntu -u root -e bash -c $cmd
}

function Run-AsUser([string]$cmd) {
    wsl -d Ubuntu -u root -e su - moadh -c $cmd
}

switch ($Action) {

    "start" {
        Write-Host "==> Maintien de WSL2 actif (sinon le conteneur minikube s'arrete avec la distro)" -ForegroundColor Cyan
        Start-Process -WindowStyle Hidden -FilePath "wsl" `
            -ArgumentList '-d', 'Ubuntu', '-u', 'root', '-e', 'bash', '-c', 'while true; do sleep 3600; done'
        Start-Sleep -Seconds 3

        Write-Host "==> Demarrage du service Docker" -ForegroundColor Cyan
        Run-Bash "systemctl start docker"

        Write-Host "==> Demarrage de Minikube (driver docker)" -ForegroundColor Cyan
        Run-AsUser "minikube start --driver=docker --memory=3000 --cpus=2"

        Write-Host "==> Etat du cluster" -ForegroundColor Cyan
        Run-AsUser "minikube status; kubectl get nodes -o wide"
    }

    "status" {
        Run-AsUser "minikube status; echo ---; kubectl get nodes; echo ---; kubectl get pods -A"
    }

    "kubectl" {
        Run-AsUser "kubectl get nodes -o wide; echo ---; kubectl get pods -A; echo ---; kubectl get svc -A"
    }

    "stop" {
        Run-AsUser "minikube stop"
    }
}
