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
BLUE='\033[0;34m'
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
        # Verificar se container tem healthcheck configurado
        has_healthcheck=$(docker inspect --format='{{.State.Health}}' $container 2>/dev/null || echo "<nil>")
        
        if [ "$has_healthcheck" = "<nil>" ]; then
            # Container não tem healthcheck, verificar apenas se está rodando
            state=$(docker inspect --format='{{.State.Status}}' $container 2>/dev/null)
            if [ "$state" = "running" ]; then
                echo -e "${GREEN}✓${NC} $container: running (no healthcheck)"
            else
                echo -e "${RED}✗${NC} $container: $state"
                all_healthy=false
            fi
        else
            # Container tem healthcheck, verificar status de saúde
            health_status=$(docker inspect --format='{{.State.Health.Status}}' $container 2>/dev/null)
            if [ "$health_status" = "healthy" ]; then
                echo -e "${GREEN}✓${NC} $container: healthy"
            elif [ "$health_status" = "starting" ]; then
                echo -e "${YELLOW}⏳${NC} $container: starting"
            else
                echo -e "${RED}✗${NC} $container: $health_status"
                all_healthy=false
            fi
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
    "9187:Postgres Exporter"
    "8081:cAdvisor"
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

has_errors=false
for container in "${containers[@]}"; do
    if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        error_count=$(docker logs --since 24h $container 2>&1 | grep -iE 'error|fatal|critical' | wc -l)
        if [ "$error_count" -gt 0 ]; then
            echo -e "${YELLOW}⚠️${NC}  $container: $error_count erros encontrados"
            has_errors=true
        fi
    fi
done

if [ "$has_errors" = false ]; then
    echo -e "${GREEN}✓${NC} Nenhum erro crítico encontrado nos logs"
fi

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
    max_connections=$(docker exec postgres-zabbix psql -U zabbix -d zabbix -t -c "SHOW max_connections;" 2>/dev/null | tr -d ' ')
    
    connection_percent=$(echo "scale=1; ($connections * 100) / $max_connections" | bc 2>/dev/null || echo "N/A")
    
    echo "  Ativas: $connections / $max_connections ($connection_percent%)"
    
    if [ "$connections" -gt 250 ]; then
        echo -e "${YELLOW}⚠️  Muitas conexões ativas${NC}"
    fi
else
    echo -e "${RED}✗${NC} Banco Zabbix NÃO ACESSÍVEL"
fi

echo ""

# ==========================================
# VERIFICAR SERVIÇOS WEB
# ==========================================
echo "🌐 Verificando Serviços Web:"
echo ""

# Zabbix Web
if curl -sf http://localhost:8080/ > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Zabbix Web respondendo (http://localhost:8080)"
else
    echo -e "${RED}✗${NC} Zabbix Web não está respondendo"
fi

# Grafana
if curl -sf http://localhost:3000/api/health > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Grafana respondendo (http://localhost:3000)"
else
    echo -e "${RED}✗${NC} Grafana não está respondendo"
fi

# Prometheus
if curl -sf http://localhost:9090/-/healthy > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Prometheus respondendo (http://localhost:9090)"
else
    echo -e "${RED}✗${NC} Prometheus não está respondendo"
fi

echo ""

# ==========================================
# VERIFICAR TARGETS DO PROMETHEUS
# ==========================================
echo "🎯 Targets do Prometheus:"
echo ""

targets_up=$(curl -s http://localhost:9090/api/v1/targets 2>/dev/null | grep -o '"health":"up"' | wc -l)
targets_down=$(curl -s http://localhost:9090/api/v1/targets 2>/dev/null | grep -o '"health":"down"' | wc -l)

if [ "$targets_up" -gt 0 ]; then
    echo -e "${GREEN}✓${NC} Targets UP: $targets_up"
fi

if [ "$targets_down" -gt 0 ]; then
    echo -e "${RED}✗${NC} Targets DOWN: $targets_down"
    echo ""
    echo "Targets com problema:"
    curl -s http://localhost:9090/api/v1/targets 2>/dev/null | \
        grep -o '"job":"[^"]*".*"health":"down"' | \
        sed 's/"job":"\([^"]*\)".*"health":"down"/  - \1/' | \
        sort -u
else
    echo -e "${GREEN}✓${NC} Todos os targets estão UP"
fi

echo ""

# ==========================================
# RESUMO FINAL
# ==========================================
echo "=========================================="
if [ "$all_healthy" = true ]; then
    echo -e "${GREEN}✅ TODOS OS SERVIÇOS ESTÃO SAUDÁVEIS${NC}"
else
    echo -e "${YELLOW}⚠️  ALGUNS SERVIÇOS APRESENTAM AVISOS${NC}"
    echo -e "${BLUE}ℹ️  Containers 'running' sem healthcheck são normais${NC}"
fi
echo "=========================================="
echo ""
echo "Data: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""