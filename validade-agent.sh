#!/bin/bash
# Script para validar configuração do Agent e conectividade com Zabbix Server

# Cores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=========================================="
echo "🔍 VALIDADOR DE AGENT ZABBIX"
echo "=========================================="
echo ""

# Ler .env se existir
if [ -f .env ]; then
    source .env
    echo -e "${GREEN}✓${NC} Arquivo .env carregado"
    ZABBIX_SERVER_IP=${SERVER_IP:-AUTO}
else
    echo -e "${YELLOW}⚠${NC}  Arquivo .env não encontrado"
    read -p "Digite o IP do Zabbix Server: " ZABBIX_SERVER_IP
fi

echo ""

# ==========================================
# OPÇÃO: Validar agent local ou remoto
# ==========================================
echo "Escolha o modo de validação:"
echo "  1) Validar agent no host remoto (via SSH)"
echo "  2) Testar conectividade de um host remoto"
echo ""
read -p "Escolha [1-2]: " MODE

echo ""

if [ "$MODE" == "1" ]; then
    # ==========================================
    # VALIDAR AGENT VIA SSH
    # ==========================================
    read -p "IP/Hostname do host remoto: " REMOTE_HOST
    read -p "Usuário SSH [root]: " SSH_USER
    SSH_USER=${SSH_USER:-root}
    
    echo ""
    echo "Conectando ao host $REMOTE_HOST..."
    
    # Executar verificações remotas
    ssh ${SSH_USER}@${REMOTE_HOST} bash << 'ENDSSH'
echo "1️⃣ Verificando se agent está instalado..."
if command -v zabbix_agent2 &> /dev/null; then
    echo "✓ Zabbix Agent 2 encontrado"
    zabbix_agent2 --version | head -1
elif command -v zabbix_agentd &> /dev/null; then
    echo "✓ Zabbix Agent (v1) encontrado"
    zabbix_agentd --version | head -1
else
    echo "✗ Agent não encontrado!"
    exit 1
fi

echo ""
echo "2️⃣ Verificando serviço..."
if systemctl is-active --quiet zabbix-agent2; then
    echo "✓ zabbix-agent2 está rodando"
elif systemctl is-active --quiet zabbix-agent; then
    echo "✓ zabbix-agent está rodando"
else
    echo "✗ Serviço não está rodando!"
    systemctl status zabbix-agent2 --no-pager || systemctl status zabbix-agent --no-pager
fi

echo ""
echo "3️⃣ Verificando configuração..."
if [ -f /etc/zabbix/zabbix_agent2.conf ]; then
    CONFIG_FILE="/etc/zabbix/zabbix_agent2.conf"
elif [ -f /etc/zabbix/zabbix_agentd.conf ]; then
    CONFIG_FILE="/etc/zabbix/zabbix_agentd.conf"
else
    echo "✗ Arquivo de configuração não encontrado!"
    exit 1
fi

echo "Configurações importantes:"
grep "^Server=" $CONFIG_FILE || echo "⚠ Server não configurado"
grep "^ServerActive=" $CONFIG_FILE || echo "⚠ ServerActive não configurado"
grep "^Hostname=" $CONFIG_FILE || echo "⚠ Hostname não configurado"
grep "^ListenPort=" $CONFIG_FILE || echo "  ListenPort=10050 (padrão)"

echo ""
echo "4️⃣ Testando agent localmente..."
if command -v zabbix_agent2 &> /dev/null; then
    zabbix_agent2 -t agent.ping
elif command -v zabbix_agentd &> /dev/null; then
    zabbix_agentd -t agent.ping
fi

echo ""
echo "5️⃣ Verificando porta..."
if ss -tuln | grep -q ":10050 "; then
    echo "✓ Porta 10050 está em escuta"
elif netstat -tuln 2>/dev/null | grep -q ":10050 "; then
    echo "✓ Porta 10050 está em escuta"
else
    echo "✗ Porta 10050 NÃO está em escuta!"
fi

echo ""
echo "6️⃣ Verificando firewall..."
if command -v ufw &> /dev/null; then
    if ufw status | grep -q "10050.*ALLOW"; then
        echo "✓ UFW permite porta 10050"
    else
        echo "⚠ UFW pode estar bloqueando porta 10050"
        echo "  Execute: sudo ufw allow 10050/tcp"
    fi
elif command -v firewall-cmd &> /dev/null; then
    if firewall-cmd --list-ports | grep -q "10050"; then
        echo "✓ Firewalld permite porta 10050"
    else
        echo "⚠ Firewalld pode estar bloqueando porta 10050"
        echo "  Execute: sudo firewall-cmd --permanent --add-port=10050/tcp"
    fi
fi
ENDSSH

    echo ""
    echo "7️⃣ Testando DO Zabbix Server PARA o host..."
    
    REMOTE_IP=$(dig +short $REMOTE_HOST 2>/dev/null || echo $REMOTE_HOST)
    
    if docker ps | grep -q zabbix-server; then
        echo "Testando com zabbix_get..."
        if docker exec zabbix-server zabbix_get -s $REMOTE_IP -k agent.ping 2>&1 | grep -q "1"; then
            echo -e "${GREEN}✓ Zabbix Server consegue acessar o agent!${NC}"
        else
            echo -e "${RED}✗ Zabbix Server NÃO consegue acessar o agent${NC}"
            echo ""
            echo "Possíveis causas:"
            echo "  • Firewall bloqueando no host remoto"
            echo "  • IP incorreto no Server= do agent"
            echo "  • Agent não está rodando"
        fi
    else
        echo -e "${YELLOW}⚠ Container zabbix-server não encontrado${NC}"
    fi

elif [ "$MODE" == "2" ]; then
    # ==========================================
    # TESTAR CONECTIVIDADE
    # ==========================================
    read -p "IP do host remoto: " REMOTE_IP
    
    echo ""
    echo "1️⃣ Testando PING..."
    if ping -c 2 -W 2 $REMOTE_IP &> /dev/null; then
        echo -e "${GREEN}✓${NC} Host responde ao ping"
    else
        echo -e "${RED}✗${NC} Host NÃO responde ao ping"
    fi
    
    echo ""
    echo "2️⃣ Testando porta 10050..."
    if timeout 3 bash -c "cat < /dev/null > /dev/tcp/$REMOTE_IP/10050" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} Porta 10050 acessível"
    else
        echo -e "${RED}✗${NC} Porta 10050 NÃO acessível"
    fi
    
    echo ""
    echo "3️⃣ Testando com zabbix_get..."
    if docker ps | grep -q zabbix-server; then
        if docker exec zabbix-server zabbix_get -s $REMOTE_IP -k agent.ping 2>&1 | grep -q "1"; then
            echo -e "${GREEN}✓${NC} Agent responde corretamente!"
        else
            echo -e "${RED}✗${NC} Agent NÃO responde"
            echo ""
            echo "Resultado do zabbix_get:"
            docker exec zabbix-server zabbix_get -s $REMOTE_IP -k agent.ping 2>&1
        fi
    else
        echo -e "${YELLOW}⚠${NC} Container zabbix-server não encontrado"
    fi
    
    echo ""
    echo "4️⃣ Testando itens básicos..."
    if docker ps | grep -q zabbix-server; then
        echo "agent.hostname:"
        docker exec zabbix-server zabbix_get -s $REMOTE_IP -k agent.hostname 2>&1
        
        echo ""
        echo "agent.version:"
        docker exec zabbix-server zabbix_get -s $REMOTE_IP -k agent.version 2>&1
        
        echo ""
        echo "system.uname:"
        docker exec zabbix-server zabbix_get -s $REMOTE_IP -k system.uname 2>&1
    fi
fi

echo ""
echo "=========================================="
echo "📋 RESUMO E PRÓXIMOS PASSOS"
echo "=========================================="
echo ""
echo "Se o agent está funcionando:"
echo "  1. Acessar Zabbix Web: http://${ZABBIX_SERVER_IP}:8080"
echo "  2. Data collection → Hosts → Create host"
echo "  3. Configurar:"
echo "     Host name: (mesmo do agent)"
echo "     Interface: $REMOTE_IP:10050"
echo "     Templates: Linux/Windows by Zabbix agent active"
echo ""
echo "Se houver problemas:"
echo "  • Verificar Server=$ZABBIX_SERVER_IP no agent"
echo "  • Liberar firewall: sudo ufw allow 10050/tcp"
echo "  • Reiniciar agent: sudo systemctl restart zabbix-agent2"
echo "  • Ver logs: sudo tail -f /var/log/zabbix/zabbix_agent2.log"
echo ""