#!/bin/bash
# Arquivo: ./scripts/healthcheck.sh
# Verificação de saúde do stack

set -e

echo "=========================================="
echo "🏥 HEALTH CHECK - Zabbix Stack"
echo "=========================================="
echo ""

# Cores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ==========================================
# VERIFICAR CONTAINERS
# ==========================================
echo "📦 Status dos Containers:"
echo ""

containers=("postgres-zabbix" "zabbix-server" "zabbix-web" "zabbix-agent" "grafana" "prometheus" "node-exporter" "postgres-exporter" "cadvisor")

all_healthy=true

for container in "${containers[@]}"; do
    if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        status=$(docker inspect --format='{{.State.Health.Status}}' $container 2>/dev/null || echo "running")
        if [ "$status" = "healthy" ] || [ "$status" = "running" ]; then
            echo -e "${GREEN}✓${NC} $container: $status"
        else
            echo -e "${RED}✗${NC} $container: $status"
            all_healthy=false
        fi
    else
        echo -e "${RED}✗${NC} $container: NOT RUNNING"
        all_healthy=false
    fi
done

echo ""

# ==========================================
# VERIFICAR PORTAS
# ==========================================
echo "🔌 Portas em Escuta:"
echo ""

ports=(
    "5432:PostgreSQL"
    "8080:Zabbix Web"
    "3000:Grafana"
    "9090:Prometheus"
    "9100:Node Exporter"
    "10050:Zabbix Agent"
    "10051:Zabbix Server"
)

for port_info in "${ports[@]}"; do
    IFS=':' read -r port service <<< "$port_info"
    if netstat -tuln 2>/dev/null | grep -q ":$port " || ss -tuln 2>/dev/null | grep -q ":$port "; then
        echo -e "${GREEN}✓${NC} $service (porta $port)"
    else
        echo -e "${RED}✗${NC} $service (porta $port) - NÃO ACESSÍVEL"
    fi
done

echo ""

# ==========================================
# VERIFICAR DISCO
# ==========================================
echo "💾 Espaço em Disco:"
echo ""

df -h | grep -E '^Filesystem|/$' | awk '{printf "%-20s %10s %10s %10s %s\n", $1, $2, $3, $4, $5}'

disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
if [ "$disk_usage" -gt 85 ]; then
    echo -e "${RED}⚠️  ATENÇÃO: Disco acima de 85% de uso!${NC}"
elif [ "$disk_usage" -gt 70 ]; then
    echo -e "${YELLOW}⚠️  Aviso: Disco acima de 70% de uso${NC}"
fi

echo ""

# ==========================================
# VERIFICAR MEMÓRIA
# ==========================================
echo "🧠 Uso de Memória:"
echo ""

free -h | awk 'NR==1 || NR==2 {printf "%-10s %10s %10s %10s\n", $1, $2, $3, $4}'

mem_usage=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100}')
if [ "$mem_usage" -gt 90 ]; then
    echo -e "${RED}⚠️  ATENÇÃO: Memória acima de 90% de uso!${NC}"
elif [ "$mem_usage" -gt 80 ]; then
    echo -e "${YELLOW}⚠️  Aviso: Memória acima de 80% de uso${NC}"
fi

echo ""

# ==========================================
# VERIFICAR VOLUMES DOCKER
# ==========================================
echo "📚 Volumes Docker:"
echo ""

docker volume ls --format "table {{.Name}}\t{{.Driver}}" | grep -E 'NAME|zabbix'

echo ""

# ==========================================
# VERIFICAR LOGS COM ERROS
# ==========================================
echo "📝 Erros Recentes nos Logs (últimas 24h):"
echo ""

for container in "${containers[@]}"; do
    if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        error_count=$(docker logs --since 24h $container 2>&1 | grep -iE 'error|fatal|critical' | wc -l)
        if [ "$error_count" -gt 0 ]; then
            echo -e "${YELLOW}⚠️${NC}  $container: $error_count erros encontrados"
        fi
    fi
done

echo ""

# ==========================================
# VERIFICAR BANCO DE DADOS
# ==========================================
echo "🗄️  PostgreSQL:"
echo ""

if docker exec postgres-zabbix pg_isready -U zabbix -d zabbix &>/dev/null; then
    echo -e "${GREEN}✓${NC} Banco Zabbix acessível"
    
    # Tamanho dos bancos
    echo ""
    echo "Tamanho dos bancos:"
    docker exec postgres-zabbix psql -U zabbix -d postgres -c "
        SELECT 
            datname as database,
            pg_size_pretty(pg_database_size(datname)) as size
        FROM pg_database
        WHERE datname IN ('zabbix', 'grafana')
        ORDER BY pg_database_size(datname) DESC;
    " 2>/dev/null || echo "Não foi possível obter tamanho dos bancos"
    
    # Conexões ativas
    echo ""
    echo "Conexões ativas:"
    connections=$(docker exec postgres-zabbix psql -U zabbix -d zabbix -t -c "SELECT count(*) FROM pg_stat_activity;" 2>/dev/null | tr -d ' ')
    echo "  Total: $connections"
else
    echo -e "${RED}✗${NC} Banco Zabbix NÃO ACESSÍVEL"
fi

echo ""

# ==========================================
# RESUMO FINAL
# ==========================================
echo "=========================================="
if [ "$all_healthy" = true ]; then
    echo -e "${GREEN}✅ TODOS OS SERVIÇOS ESTÃO SAUDÁVEIS${NC}"
else
    echo -e "${RED}❌ ALGUNS SERVIÇOS APRESENTAM PROBLEMAS${NC}"
fi
echo "=========================================="
echo ""
echo "Data: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""