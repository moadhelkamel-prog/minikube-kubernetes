Clear-Host
Write-Host "=== Etape 1 - Audit et installation des outils ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "[1.1] Audit des outils presents" -ForegroundColor Yellow
foreach ($c in 'git','vagrant','VBoxManage','minikube','kubectl') {
  $p = Get-Command $c -ErrorAction SilentlyContinue
  if ($p) { '{0,-12} {1}' -f $c, $p.Source } else { '{0,-12} MANQUANT' -f $c }
}
Write-Host ""
Write-Host "[1.2] Versions installees" -ForegroundColor Yellow
git --version
vagrant --version
VBoxManage --version
minikube version
kubectl version --client