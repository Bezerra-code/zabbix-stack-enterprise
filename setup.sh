#!/bin/bash
# Setup Wizard - Configuração Inicial do Stack Zabbix
# Detecta automaticamente a infraestrutura e configura o ambiente

set -e

# Cores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

clear
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                                                                ║"
echo "║        🚀 SETUP WIZARD - STACK ZABBIX ENTERPRISE               ║"
echo "║                                                                ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# ==========================================
# VERIFICAR PRÉ-REQUISITOS
# ==========================================
echo -e "${BLUE}📋 Verificando pré-requisitos...${NC}"
echo ""

# Docker
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | cut -d',' -f1)
    echo -e "${GREEN}✓${NC} Docker instalado: v$DOCKER_VERSION"
else
    echo -e "${RED}✗${NC} Docker não encontrado!"
    echo "   Instale: curl -fsSL https://get.docker.com | sh"
    exit 1
fi

# Docker Compose
if command -v docker compose &> /dev/null || command -v docker-compose &> /dev/null; then
    echo -e "${GREEN}✓${NC} Docker Compose instalado"
else
    echo -e "${RED}✗${NC} Docker Compose não encontrado!"
    exit 1
fi

echo ""

# ==========================================
# DETECTAR AMBIENTE
# ==========================================
echo -e "${BLUE}🔍 Detectando ambiente...${NC}"
echo ""

# Detectar sistema operacional
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if grep -qi microsoft /proc/version 2>/dev/null; then
        ENV_TYPE="wsl"
        echo -e "Ambiente detectado: ${YELLOW}WSL (Windows Subsystem for Linux)${NC}"
    else
        ENV_TYPE="linux"
        echo -e "Ambiente detectado: ${GREEN}Linux Nativo${NC}"
    fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
    ENV_TYPE="macos"
    echo -e "Ambiente detectado: ${CYAN}macOS${NC}"
else
    ENV_TYPE="unknown"
    echo -e "Ambiente detectado: ${YELLOW}Desconhecido${NC}"
fi

echo ""

# ==========================================
# DETECTAR IPs DISPONÍVEIS
# ==========================================
echo -e "${BLUE}🌐 Detectando endereços IP...${NC}"
echo ""

# Obter todos os IPs (exceto loopback)
mapfile -t ALL_IPS < <(hostname -I 2>/dev/null || ip addr show | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | cut -d/ -f1)

if [ ${#ALL_IPS[@]} -eq 0 ]; then
    echo -e "${RED}✗${NC} Nenhum IP detectado!"
    ALL_IPS=("127.0.0.1")
fi

# Filtrar IPs relevantes
PHYSICAL_IPS=()
DOCKER_IPS=()
WSL_IPS=()

for ip in "${ALL_IPS[@]}"; do
    if [[ $ip =~ ^172\.1[7-9]\. ]] || [[ $ip =~ ^172\.2[0-9]\. ]]; then
        DOCKER_IPS+=("$ip")
    elif [[ $ip =~ ^172\. ]]; then
        WSL_IPS+=("$ip")
    elif [[ $ip =~ ^192\.168\. ]] || [[ $ip =~ ^10\. ]] || [[ ! $ip =~ ^172\. ]]; then
        PHYSICAL_IPS+=("$ip")
    fi
done

echo "IPs encontrados:"
echo ""

if [ ${#PHYSICAL_IPS[@]} -gt 0 ]; then
    echo -e "${GREEN}IPs de Rede Física/Corporativa:${NC}"
    for ip in "${PHYSICAL_IPS[@]}"; do
        echo "  • $ip"
    done
    RECOMMENDED_IP="${PHYSICAL_IPS[0]}"
fi

if [ ${#WSL_IPS[@]} -gt 0 ]; then
    echo -e "${YELLOW}IPs WSL/Virtual:${NC}"
    for ip in "${WSL_IPS[@]}"; do
        echo "  • $ip"
    done
    if [ -z "$RECOMMENDED_IP" ]; then
        RECOMMENDED_IP="${WSL_IPS[0]}"
    fi
fi

if [ ${#DOCKER_IPS[@]} -gt 0 ]; then
    echo -e "${CYAN}IPs Docker (interno):${NC}"
    for ip in "${DOCKER_IPS[@]}"; do
        echo "  • $ip"
    done
fi

echo ""

if [ -z "$RECOMMENDED_IP" ]; then
    RECOMMENDED_IP="${ALL_IPS[0]}"
fi

# ==========================================
# MODO DE CONFIGURAÇÃO
# ==========================================
echo -e "${MAGENTA}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}║  Escolha o modo de configuração:                       ║${NC}"
echo -e "${MAGENTA}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "  1) 🚀 Rápido (Recomendado) - Detecção automática"
echo "  2) ⚙️  Avançado - Configuração manual"
echo "  3) 📦 Desenvolvimento - Apenas containers internos"
echo ""
read -p "Escolha [1-3]: " CONFIG_MODE

case $CONFIG_MODE in
    1)
        echo ""
        echo -e "${GREEN}✓${NC} Modo Rápido selecionado"
        SETUP_MODE="auto"
        ;;
    2)
        echo ""
        echo -e "${CYAN}✓${NC} Modo Avançado selecionado"
        SETUP_MODE="manual"
        ;;
    3)
        echo ""
        echo -e "${YELLOW}✓${NC} Modo Desenvolvimento selecionado"
        SETUP_MODE="dev"
        ;;
    *)
        echo -e "${RED}Opção inválida. Usando modo Rápido.${NC}"
        SETUP_MODE="auto"
        ;;
esac

echo ""

# ==========================================
# CONFIGURAÇÃO BASEADA NO MODO
# ==========================================

if [ "$SETUP_MODE" == "dev" ]; then
    # Modo desenvolvimento - tudo localhost
    SERVER_IP="127.0.0.1"
    BIND_INTERFACE="127.0.0.1"
    POSTGRES_EXTERNAL="no"
    
    echo -e "${YELLOW}Configuração de Desenvolvimento:${NC}"
    echo "  • Acesso apenas localhost"
    echo "  • Sem exposição externa"
    echo "  • Ideal para testes locais"
    echo ""

elif [ "$SETUP_MODE" == "auto" ]; then
    # Modo automático
    SERVER_IP="$RECOMMENDED_IP"
    BIND_INTERFACE="0.0.0.0"
    POSTGRES_EXTERNAL="no"
    
    echo -e "${GREEN}Configuração Automática:${NC}"
    echo "  • IP Detectado: $SERVER_IP"
    echo "  • Bind: Todas interfaces (0.0.0.0)"
    echo "  • PostgreSQL: Apenas interno"
    echo ""
    
    read -p "Confirmar esta configuração? [S/n]: " confirm
    if [[ "$confirm" =~ ^[Nn]$ ]]; then
        SETUP_MODE="manual"
        echo ""
        echo -e "${CYAN}Alterando para modo manual...${NC}"
        echo ""
    fi
fi

if [ "$SETUP_MODE" == "manual" ]; then
    # Modo manual
    echo -e "${CYAN}=== Configuração Manual ===${NC}"
    echo ""
    
    # IP do servidor
    echo "IPs disponíveis:"
    for i in "${!ALL_IPS[@]}"; do
        echo "  $((i+1))) ${ALL_IPS[$i]}"
    done
    echo ""
    read -p "Escolha o número ou digite um IP customizado [$RECOMMENDED_IP]: " ip_choice
    
    if [[ "$ip_choice" =~ ^[0-9]+$ ]] && [ "$ip_choice" -le "${#ALL_IPS[@]}" ]; then
        SERVER_IP="${ALL_IPS[$((ip_choice-1))]}"
    elif [ -n "$ip_choice" ]; then
        SERVER_IP="$ip_choice"
    else
        SERVER_IP="$RECOMMENDED_IP"
    fi
    
    echo ""
    
    # Bind interface
    echo "Bind interface:"
    echo "  1) 0.0.0.0 (Todas - Recomendado)"
    echo "  2) 127.0.0.1 (Apenas local)"
    echo "  3) $SERVER_IP (Apenas este IP)"
    echo ""
    read -p "Escolha [1-3] [1]: " bind_choice
    
    case $bind_choice in
        2)
            BIND_INTERFACE="127.0.0.1"
            ;;
        3)
            BIND_INTERFACE="$SERVER_IP"
            ;;
        *)
            BIND_INTERFACE="0.0.0.0"
            ;;
    esac
    
    echo ""
    
    # PostgreSQL externo
    read -p "Expor PostgreSQL externamente? [y/N]: " postgres_ext
    if [[ "$postgres_ext" =~ ^[Yy]$ ]]; then
        POSTGRES_EXTERNAL="yes"
    else
        POSTGRES_EXTERNAL="no"
    fi
    
    echo ""
fi

# ==========================================
# SENHAS
# ==========================================
echo -e "${BLUE}🔐 Configuração de Senhas${NC}"
echo ""

read -p "Gerar senhas automaticamente? [S/n]: " auto_pass
if [[ ! "$auto_pass" =~ ^[Nn]$ ]]; then
    DB_PASSWORD=$(openssl rand -base64 24)
    GRAFANA_ADMIN_PASSWORD=$(openssl rand -base64 24)
    MONITORING_PASSWORD=$(openssl rand -base64 24)
    
    echo -e "${GREEN}✓${NC} Senhas geradas automaticamente"
else
    read -sp "Senha PostgreSQL: " DB_PASSWORD
    echo ""
    read -sp "Senha Grafana Admin: " GRAFANA_ADMIN_PASSWORD
    echo ""
    read -sp "Senha Monitoring: " MONITORING_PASSWORD
    echo ""
fi

echo ""

# ==========================================
# HOSTNAME E DOMÍNIO
# ==========================================
DEFAULT_HOSTNAME=$(hostname -s)
read -p "Hostname do servidor [$DEFAULT_HOSTNAME]: " HOSTNAME
HOSTNAME=${HOSTNAME:-$DEFAULT_HOSTNAME}

read -p "Domínio [empresa.local]: " DOMAIN
DOMAIN=${DOMAIN:-empresa.local}

echo ""

# ==========================================
# RESUMO DA CONFIGURAÇÃO
# ==========================================
echo -e "${MAGENTA}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}║  📋 RESUMO DA CONFIGURAÇÃO                             ║${NC}"
echo -e "${MAGENTA}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Servidor:${NC}"
echo "  Hostname: $HOSTNAME"
echo "  Domínio: $DOMAIN"
echo "  IP: $SERVER_IP"
echo ""
echo -e "${CYAN}Rede:${NC}"
echo "  Bind Interface: $BIND_INTERFACE"
echo "  PostgreSQL Externo: $POSTGRES_EXTERNAL"
echo ""
echo -e "${CYAN}Acessos:${NC}"
echo "  Zabbix Web: http://$SERVER_IP:8080"
echo "  Grafana: http://$SERVER_IP:3000"
echo "  Prometheus: http://$SERVER_IP:9090"
echo ""
echo -e "${CYAN}Agents Externos:${NC}"
echo "  Configurar Server=$SERVER_IP no agent"
echo ""

read -p "Confirmar e criar ambiente? [S/n]: " final_confirm
if [[ "$final_confirm" =~ ^[Nn]$ ]]; then
    echo -e "${YELLOW}Setup cancelado.${NC}"
    exit 0
fi

echo ""

# ==========================================
# CRIAR .ENV
# ==========================================
echo -e "${BLUE}📝 Criando arquivo .env...${NC}"

cat > .env <<EOF
# ==========================================
# STACK ZABBIX ENTERPRISE - Configuração
# Gerado automaticamente em: $(date)
# ==========================================

# Identificação
HOSTNAME=$HOSTNAME
DOMAIN=$DOMAIN

# Rede
SERVER_IP=$SERVER_IP
BIND_INTERFACE=$BIND_INTERFACE
ZABBIX_SERVER_PORT=10051
ZABBIX_WEB_PORT=8080
GRAFANA_PORT=3000
PROMETHEUS_PORT=9090
DOCKER_SUBNET=172.20.0.0/16

# PostgreSQL
DB_USER=zabbix
DB_PASSWORD=$DB_PASSWORD
POSTGRES_EXTERNAL=$POSTGRES_EXTERNAL

# Grafana
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=$GRAFANA_ADMIN_PASSWORD

# Monitoring
MONITORING_USER=monitoring
MONITORING_PASSWORD=$MONITORING_PASSWORD

# Ambiente
ENVIRONMENT=production
TZ=America/Sao_Paulo
EOF

echo -e "${GREEN}✓${NC} Arquivo .env criado"
echo ""

# ==========================================
# CRIAR ESTRUTURA DE PASTAS
# ==========================================
echo -e "${BLUE}📁 Criando estrutura de pastas...${NC}"

mkdir -p grafana/dashboards
mkdir -p grafana/provisioning/{datasources,dashboards}
mkdir -p postgres/{init,backups}
mkdir -p prometheus/alerts
mkdir -p scripts
mkdir -p zabbix/{alertscripts,externalscripts,modules,enc,ssh_keys,ssl/{certs,keys,ca},snmptraps,mibs}

chmod +x postgres/init/*.sh 2>/dev/null || true
chmod +x scripts/*.sh 2>/dev/null || true

echo -e "${GREEN}✓${NC} Estrutura criada"
echo ""

# ==========================================
# CRIAR ARQUIVO DE CONFIGURAÇÃO DOS AGENTS
# ==========================================
echo -e "${BLUE}📋 Criando templates de configuração dos agents...${NC}"

# Linux Agent Config
cat > agent-config-linux.conf <<EOF
# Configuração para Zabbix Agent 2 - Linux
# Copie este arquivo para /etc/zabbix/zabbix_agent2.conf no host monitorado

Server=$SERVER_IP
ServerActive=$SERVER_IP
Hostname=ALTERE_PARA_NOME_UNICO
ListenPort=10050
ListenIP=0.0.0.0
LogFile=/var/log/zabbix/zabbix_agent2.log
DebugLevel=3
Timeout=30
EOF

# Windows Agent Config
cat > agent-config-windows.conf <<EOF
# Configuração para Zabbix Agent 2 - Windows
# Copie este conteúdo para C:\Program Files\Zabbix Agent 2\zabbix_agent2.conf

Server=$SERVER_IP
ServerActive=$SERVER_IP
Hostname=ALTERE_PARA_NOME_UNICO
ListenPort=10050
LogFile=C:\Program Files\Zabbix Agent 2\zabbix_agent2.log
DebugLevel=3
Timeout=30
EOF

echo -e "${GREEN}✓${NC} Templates criados:"
echo "  • agent-config-linux.conf"
echo "  • agent-config-windows.conf"
echo ""

# ==========================================
# INICIAR STACK
# ==========================================
echo -e "${MAGENTA}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}║  🚀 INICIANDO STACK                                    ║${NC}"
echo -e "${MAGENTA}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

read -p "Iniciar containers agora? [S/n]: " start_now
if [[ ! "$start_now" =~ ^[Nn]$ ]]; then
    echo ""
    echo "Iniciando containers..."
    docker compose up -d
    
    echo ""
    echo "Aguardando inicialização (30 segundos)..."
    sleep 30
    
    # Executar healthcheck se existir
    if [ -f "./scripts/healthcheck.sh" ]; then
        echo ""
        ./scripts/healthcheck.sh
    fi
fi

echo ""

# ==========================================
# INFORMAÇÕES FINAIS
# ==========================================
echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅ SETUP CONCLUÍDO COM SUCESSO!                       ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}📊 Acessos:${NC}"
echo "  Zabbix Web: http://$SERVER_IP:8080"
echo "    Usuário: Admin"
echo "    Senha: zabbix (ALTERE IMEDIATAMENTE!)"
echo ""
echo "  Grafana: http://$SERVER_IP:3000"
echo "    Usuário: admin"
echo "    Senha: (verificar em .env)"
echo ""
echo -e "${CYAN}🔧 Configurar Agents:${NC}"
echo "  Use os arquivos gerados:"
echo "    • agent-config-linux.conf"
echo "    • agent-config-windows.conf"
echo ""
echo -e "${CYAN}📝 Próximos Passos:${NC}"
echo "  1. Acessar Zabbix Web e TROCAR senha padrão"
echo "  2. Instalar agents nos hosts a monitorar"
echo "  3. Adicionar hosts no Zabbix Web"
echo "  4. Configurar datasource Zabbix no Grafana"
echo "  5. Importar dashboards do Grafana"
echo ""
echo -e "${YELLOW}⚠️  Importante:${NC}"
echo "  • Senhas salvas em .env (NÃO commitar no Git!)"
echo "  • Documentação completa em README.md"
echo "  • Backup automático: ./scripts/backup.sh"
echo ""
echo -e "${BLUE}Para gerenciar o stack:${NC}"
echo "  docker compose ps           # Ver status"
echo "  docker compose logs -f      # Ver logs"
echo "  docker compose restart      # Reiniciar"
echo "  docker compose down         # Parar tudo"
echo ""