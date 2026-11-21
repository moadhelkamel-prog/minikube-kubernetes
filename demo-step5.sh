#!/bin/bash
# Etape 5 : test applicatif
set -u
echo "URL du service :"
URL=$(minikube service web --url 2>/dev/null)
echo "$URL"
echo ""
echo "Reponse HTTP :"
curl -s -o /dev/null -w "HTTP %{http_code}\n" "$URL"
echo ""
echo "Extrait de la page :"
curl -s "$URL" | head -3