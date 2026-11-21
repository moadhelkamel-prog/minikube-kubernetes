Clear-Host
Write-Host "=== Etape 5 - kubectl get nodes et test applicatif ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "[5.1] kubectl get nodes -o wide" -ForegroundColor Yellow
wsl -d Ubuntu -u root -e su - moadh -c "kubectl get nodes -o wide"
Write-Host ""
Write-Host "[5.2] kubectl get pods -A" -ForegroundColor Yellow
wsl -d Ubuntu -u root -e su - moadh -c "kubectl get pods -A"
Write-Host ""
Write-Host "[5.3] Etat du deploiement web et du service" -ForegroundColor Yellow
wsl -d Ubuntu -u root -e su - moadh -c "kubectl get deployment,svc,pods 2>/dev/null | grep -E 'NAME|web'"
Write-Host ""
Write-Host "[5.4] curl du service (NodePort)" -ForegroundColor Yellow
wsl -d Ubuntu -u root -e su - moadh -c "URL=`$(minikube service web --url); echo `$URL; curl -s -o /dev/null -w 'HTTP %{http_code}\n' `$URL"