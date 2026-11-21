@echo off
REM Demo pour le professeur - lance demo-prof.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0demo-prof.ps1" %*
pause