#!/bin/bash
echo "===================================="
echo "   LIMPEZA COMPLETA DO DOCKER"
echo "   (containers, imagens, volumes, redes, cache)"
echo "===================================="
echo

read -p "Tem certeza que deseja APAGAR TUDO do Docker? (y/N): " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Operação cancelada."
    exit 0
fi

echo "Parando containers..."
docker stop $(docker ps -aq) 2>/dev/null

echo "Removendo containers..."
docker rm -f $(docker ps -aq) 2>/dev/null

echo "Removendo imagens..."
docker rmi -f $(docker images -q) 2>/dev/null

echo "Removendo volumes..."
docker volume rm $(docker volume ls -q) 2>/dev/null

echo "Removendo redes..."
docker network rm $(docker network ls -q) 2>/dev/null

echo "Executando prune final..."
docker system prune -a --volumes -f

echo
echo "✅ Docker completamente limpo!"
echo "Use 'docker ps -a', 'docker images' e 'docker volume ls' para verificar."
