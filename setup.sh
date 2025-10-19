#!/bin/bash
# Setup Wizard - Stack Zabbix Enterprise
# Instalação automática com verificação de dependências

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Banner
clear
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                                                                ║"
echo "║        🚀 SETUP WIZARD - STACK ZABBIX ENTERPRISE               ║"
echo "║                                                                ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# ==========================================
# VERIFICAR E INSTALAR DOCKER
# ==========================================
echo -e "${BLUE}📋 Verificando pré-requisitos...${NC}"
echo ""

if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}⚠️  Docker não encontrado!${NC}"
    echo ""
    read -p "Deseja instalar o Docker automaticamente? (s/N): " install_docker
    
    if [[ "$install_docker" =~ ^[Ss]$ ]]; then
        echo ""
        echo -e "${BLUE}📦 Instalando Docker...${NC}"
        
        # Instalar Docker
        curl -fsSL https://get.docker.com | sh
        
        # Adicionar usuário ao grupo docker
        echo ""
        echo -e "${BLUE}👤 Adicionando usuário ao grupo docker...${NC}"
        sudo usermod -aG docker $USER
        
        # Habilitar e iniciar Docker
        echo -e "${BLUE}🔧 Habilitando serviço Docker...${NC}"
        sudo systemctl enable docker
        sudo systemctl start docker
        
        echo ""
        echo -e "${GREEN}✓ Docker instalado com sucesso!${NC}"
        echo -e "${YELLOW}⚠️  IMPORTANTE: Você precisa fazer LOGOUT/LOGIN para aplicar as permissões${NC}"
        echo -e "${YELLOW}   Ou execute: newgrp docker${NC}"
        echo ""
        
        # Executar newgrp automaticamente
        echo -e "${BLUE}🔄 Aplicando permissões...${NC}"
        exec sg docker "$0 $*"
    else
        echo ""
        echo -e "${RED}❌ Docker é necessário para continuar!${NC}"
        echo ""
        echo "Instale manualmente:"
        echo "  curl -fsSL https://get.docker.com | sh"
        echo "  sudo usermod -aG docker \$USER"
        echo "  newgrp docker"
        echo ""
        exit 1
    fi
else
    echo -e "${GREEN}✓ Docker encontrado: $(docker --version)${NC}"
fi

# Verificar se Docker está rodando
if ! docker ps &> /dev/null; then
    echo -e "${YELLOW}⚠️  Docker não está rodando ou você não tem permissões${NC}"
    echo ""
    echo "Tente:"
    echo "  sudo systemctl start docker"
    echo "  sudo usermod -aG docker \$USER"
    echo "  newgrp docker"
    echo ""
    exit 1
fi

# ==========================================
# VERIFICAR DOCKER COMPOSE
# ==========================================
if ! command -v docker compose &> /dev/null && ! command -v docker-compose &> /dev/null; then
    echo -e "${YELLOW}⚠️  Docker Compose não encontrado!${NC}"
    echo ""
    read -p "Deseja instalar o Docker Compose automaticamente? (s/N): " install_compose
    
    if [[ "$install_compose" =~ ^[Ss]$ ]]; then
        echo ""
        echo -e "${BLUE}📦 Instalando Docker Compose...${NC}"
        
        # Docker Compose v2 já vem com o Docker moderno
        # Mas vamos garantir instalação manual se necessário
        COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
        
        sudo curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        
        echo -e "${GREEN}✓ Docker Compose instalado: $(docker-compose --version)${NC}"
    else
        echo -e "${RED}❌ Docker Compose é necessário para continuar!${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✓ Docker Compose encontrado${NC}"
fi

echo ""

# ==========================================
# VERIFICAR ESTRUTURA DE PASTAS
# ==========================================
echo -e "${BLUE}📁 Verificando estrutura de pastas...${NC}"
echo ""

folders=(
    "grafana/dashboards"
    "grafana/provisioning/datasources"
    "grafana/provisioning/dashboards"
    "postgres/init"
    "postgres/backups"
    "prometheus/alerts"
    "scripts"
    "zabbix/alertscripts"
    "zabbix/externalscripts"
)

for folder in "${folders[@]}"; do
    if [ ! -d "$folder" ]; then
        echo -e "${YELLOW}  → Criando: $folder${NC}"
        mkdir -p "$folder"
    else
        echo -e "${GREEN}  ✓ $folder${NC}"
    fi
done

echo ""

# ==========================================
# FUNÇÃO: GERAR SENHA SEGURA PARA URLs
# ==========================================
generate_safe_password() {
    # Gera senha de 32 caracteres sem caracteres problemáticos para URLs
    # Evita: / @ : ? # [ ] % + = 
    LC_ALL=C tr -dc 'A-Za-z0-9!*_-' < /dev/urandom | head -c 32
}

# ==========================================
# VERIFICAR ARQUIVO .env
# ==========================================
echo -e "${BLUE}🔐 Configurando variáveis de ambiente...${NC}"
echo ""

if [ ! -f .env ]; then
    if [ -f .env.example ]; then
        echo -e "${YELLOW}⚠️  Arquivo .env não encontrado!${NC}"
        echo ""
        read -p "Deseja criar .env com senhas geradas automaticamente? (s/N): " create_env
        
        if [[ "$create_env" =~ ^[Ss]$ ]]; then
            echo ""
            echo -e "${BLUE}🔐 Gerando senhas seguras...${NC}"
            
            # Gerar senhas seguras (compatíveis com URLs)
            DB_PASSWORD=$(generate_safe_password)
            GRAFANA_PASSWORD=$(generate_safe_password)
            MONITORING_PASSWORD=$(generate_safe_password)
            
            # Pedir hostname
            echo ""
            read -p "Digite o hostname do servidor (ou pressione Enter para usar 'zabbix-server'): " HOSTNAME_INPUT
            HOSTNAME=${HOSTNAME_INPUT:-zabbix-server}
            
            # Criar .env
            cat > .env << EOF
# Stack de Monitoramento Enterprise
# Arquivo gerado automaticamente em $(date)

# ==========================================
# GERAL
# ==========================================
DOMAIN=localhost
HOSTNAME=${HOSTNAME}

# ==========================================
# POSTGRESQL
# ==========================================
DB_USER=zabbix
DB_PASSWORD=${DB_PASSWORD}

# ==========================================
# GRAFANA
# ==========================================
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=${GRAFANA_PASSWORD}

# ==========================================
# POSTGRES EXPORTER (Monitoramento)
# ==========================================
MONITORING_USER=monitoring
MONITORING_PASSWORD=${MONITORING_PASSWORD}
EOF
            
            echo -e "${GREEN}✓ Arquivo .env criado com senhas seguras!${NC}"
            echo ""
            echo -e "${YELLOW}📝 IMPORTANTE: Anote as senhas abaixo (ou salve o arquivo .env)${NC}"
            echo ""
            echo "╔════════════════════════════════════════════════════════════════╗"
            echo "║                    CREDENCIAIS GERADAS                         ║"
            echo "╚════════════════════════════════════════════════════════════════╝"
            echo ""
            echo "PostgreSQL:"
            echo "  Usuário: zabbix"
            echo "  Senha: ${DB_PASSWORD}"
            echo ""
            echo "Grafana (http://localhost:3000):"
            echo "  Usuário: admin"
            echo "  Senha: ${GRAFANA_PASSWORD}"
            echo ""
            echo "Zabbix Web (http://localhost:8080):"
            echo "  Usuário: Admin"
            echo "  Senha: zabbix (altere após primeiro login!)"
            echo ""
            echo "Monitoring User (interno):"
            echo "  Usuário: monitoring"
            echo "  Senha: ${MONITORING_PASSWORD}"
            echo ""
            echo "╚════════════════════════════════════════════════════════════════╝"
            echo ""
            
            read -p "Pressione Enter para continuar..."
            
        else
            echo ""
            echo -e "${YELLOW}📝 Criando .env manualmente...${NC}"
            cp .env.example .env
            echo -e "${GREEN}✓ Arquivo .env criado!${NC}"
            echo ""
            echo -e "${YELLOW}⚠️  IMPORTANTE: Edite o arquivo .env e altere TODAS as senhas!${NC}"
            echo ""
            read -p "Deseja editar o .env agora? (s/N): " edit_env
            
            if [[ "$edit_env" =~ ^[Ss]$ ]]; then
                ${EDITOR:-nano} .env
            else
                echo ""
                echo -e "${RED}⚠️  LEMBRE-SE: Edite o .env antes de subir o stack!${NC}"
                echo "  nano .env"
                echo ""
            fi
        fi
    else
        echo -e "${RED}❌ Arquivo .env.example não encontrado!${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✓ Arquivo .env encontrado${NC}"
    
    # Verificar se senhas foram alteradas
    if grep -q "ALTERE_ESTA_SENHA" .env || grep -q "ALTERE_SENHA" .env; then
        echo -e "${RED}⚠️  ATENÇÃO: Senhas padrão detectadas no .env!${NC}"
        echo ""
        read -p "Deseja gerar novas senhas automaticamente? (s/N): " regen_pass
        
        if [[ "$regen_pass" =~ ^[Ss]$ ]]; then
            echo ""
            echo -e "${BLUE}🔐 Gerando novas senhas...${NC}"
            
            # Backup do .env atual
            cp .env .env.backup
            
            # Gerar novas senhas
            DB_PASSWORD=$(generate_safe_password)
            GRAFANA_PASSWORD=$(generate_safe_password)
            MONITORING_PASSWORD=$(generate_safe_password)
            
            # Atualizar .env
            sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=${DB_PASSWORD}/" .env
            sed -i "s/GRAFANA_ADMIN_PASSWORD=.*/GRAFANA_ADMIN_PASSWORD=${GRAFANA_PASSWORD}/" .env
            sed -i "s/MONITORING_PASSWORD=.*/MONITORING_PASSWORD=${MONITORING_PASSWORD}/" .env
            
            echo -e "${GREEN}✓ Senhas atualizadas!${NC}"
            echo ""
            echo "Backup salvo em: .env.backup"
            echo ""
        else
            read -p "Deseja editar o .env manualmente? (s/N): " edit_env
            
            if [[ "$edit_env" =~ ^[Ss]$ ]]; then
                ${EDITOR:-nano} .env
            fi
        fi
    fi
fi

echo ""

# ==========================================
# VERIFICAR PERMISSÕES DOS SCRIPTS
# ==========================================
echo -e "${BLUE}🔧 Configurando permissões...${NC}"
echo ""

scripts=(
    "postgres/init/01-create-monitoring-user.sh"
    "scripts/backup.sh"
    "scripts/healthcheck.sh"
    "scripts/cleanup.sh"
)

for script in "${scripts[@]}"; do
    if [ -f "$script" ]; then
        chmod +x "$script"
        echo -e "${GREEN}  ✓ $script${NC}"
    fi
done

echo ""

# ==========================================
# INICIAR STACK
# ==========================================
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                    PRONTO PARA INICIAR!                        ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo -e "${GREEN}✅ Todos os pré-requisitos verificados!${NC}"
echo ""
echo "O que você deseja fazer?"
echo ""
echo "  1) Subir o stack completo"
echo "  2) Apenas verificar configuração (docker compose config)"
echo "  3) Sair (subir manualmente depois)"
echo ""
read -p "Escolha uma opção (1-3): " option

case $option in
    1)
        echo ""
        echo -e "${BLUE}🚀 Subindo o stack...${NC}"
        echo ""
        docker compose up -d
        echo ""
        echo "╔════════════════════════════════════════════════════════════════╗"
        echo "║                    ✅ STACK INICIADO!                          ║"
        echo "╚════════════════════════════════════════════════════════════════╝"
        echo ""
        echo "Aguarde ~30 segundos para inicialização completa..."
        sleep 5
        echo ""
        echo "📊 Status dos containers:"
        docker compose ps
        echo ""
        echo "🌐 Acessos:"
        echo "  • Zabbix Web:  http://localhost:8080"
        echo "    User: Admin | Pass: zabbix"
        echo ""
        echo "  • Grafana:     http://localhost:3000"
        echo "    User: admin | Pass: (veja .env)"
        echo ""
        echo "  • Prometheus:  http://localhost:9090"
        echo ""
        echo "📝 Para verificar saúde do stack:"
        echo "  ./scripts/healthcheck.sh"
        echo ""
        ;;
    2)
        echo ""
        echo -e "${BLUE}🔍 Verificando configuração...${NC}"
        echo ""
        docker compose config
        echo ""
        echo -e "${GREEN}✓ Configuração válida!${NC}"
        echo ""
        echo "Para subir o stack:"
        echo "  docker compose up -d"
        echo ""
        ;;
    3)
        echo ""
        echo -e "${BLUE}👋 Setup concluído!${NC}"
        echo ""
        echo "Para subir o stack manualmente:"
        echo "  docker compose up -d"
        echo ""
        echo "Para verificar saúde:"
        echo "  ./scripts/healthcheck.sh"
        echo ""
        ;;
    *)
        echo ""
        echo -e "${RED}Opção inválida!${NC}"
        echo ""
        ;;
esac