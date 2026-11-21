@echo off
REM Wrapper pour lancer minikube-wsl.ps1 sans toucher a la execution policy
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0minikube-wsl.ps1" %*
