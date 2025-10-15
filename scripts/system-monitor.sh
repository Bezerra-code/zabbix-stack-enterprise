#!/bin/bash
# Arquivo: ./scripts/system-monitor.sh
# Monitoramento completo do sistema Ubuntu

set -e

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=========================================="
echo "🖥️  MONITORAMENTO DO SISTEMA"
echo "=========================================="
echo ""

# ==========================================
# INFORMAÇÕES GERAIS
# ==========================================
echo -e "${BLUE}📊 INFORMAÇÕES GERAIS${NC}"
echo "-------------------------------------------"
echo "Hostname: $(hostname)"
echo "IP Principal: $(hostname -I | awk '{print $1}')"
echo "SO: $(lsb_release -d | cut -f2)"
echo "Kernel: $(uname -r)"
echo "Uptime: $(uptime -p)"
echo "Data/Hora: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# ==========================================
# CPU
# ==========================================
echo -e "${BLUE}⚙️  CPU${NC}"
echo "-------------------------------------------"
CPU_CORES=$(nproc)
CPU_MODEL=$(lscpu | grep "Model name" | cut -d':' -f2 | xargs)
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
LOAD_AVG=$(uptime | awk -F'load average:' '{print $2}')

echo "Modelo: $CPU_MODEL"
echo "Núcleos: $CPU_CORES"
echo "Uso atual: ${CPU_USAGE}%"
echo "Load Average:$LOAD_AVG"

# Alerta de CPU
if (( $(echo "$CPU_USAGE > 80" | bc -l) )); then
    echo -e "${RED}⚠️  ATENÇÃO: CPU acima de 80%!${NC}"
elif (( $(echo "$CPU_USAGE > 70" | bc -l) )); then
    echo -e "${YELLOW}⚠️  Aviso: CPU acima de 70%${NC}"
else
    echo -e "${GREEN}✓ CPU OK${NC}"
fi
echo ""

# ==========================================
# MEMÓRIA
# ==========================================
echo -e "${BLUE}🧠 MEMÓRIA${NC}"
echo "-------------------------------------------"
MEM_TOTAL=$(free -h | awk '/^Mem:/ {print $2}')
MEM_USED=$(free -h | awk '/^Mem:/ {print $3}')
MEM_FREE=$(free -h | awk '/^Mem:/ {print $4}')
MEM_AVAILABLE=$(free -h | awk '/^Mem:/ {print $7}')
MEM_PERCENT=$(free | awk '/^Mem:/ {printf "%.1f", $3/$2 * 100}')

echo "Total: $MEM_TOTAL"
echo "Usado: $MEM_USED (${MEM_PERCENT}%)"
echo "Livre: $MEM_FREE"
echo "Disponível: $MEM_AVAILABLE"

# Alerta de Memória
if (( $(echo "$MEM_PERCENT > 90" | bc -l) )); then
    echo -e "${RED}⚠️  ATENÇÃO: Memória acima de 90%!${NC}"
elif (( $(echo "$MEM_PERCENT > 80" | bc -l) )); then
    echo -e "${YELLOW}⚠️  Aviso: Memória acima de 80%${NC}"
else
    echo -e "${GREEN}✓ Memória OK${NC}"
fi
echo ""

# ==========================================
# SWAP
# ==========================================
echo -e "${BLUE}💾 SWAP${NC}"
echo "-------------------------------------------"
SWAP_TOTAL=$(free -h | awk '/^Swap:/ {print $2}')
SWAP_USED=$(free -h | awk '/^Swap:/ {print $3}')
SWAP_FREE=$(free -h | awk '/^Swap:/ {print $4}')

if [ "$SWAP_TOTAL" = "0B" ]; then
    echo "SWAP não configurado"
else
    SWAP_PERCENT=$(free | awk '/^Swap:/ {if($2>0) printf "%.1f", $3/$2 * 100; else print "0"}')
    echo "Total: $SWAP_TOTAL"
    echo "Usado: $SWAP_USED (${SWAP_PERCENT}%)"
    echo "Livre: $SWAP_FREE"
fi
echo ""

# ==========================================
# DISCO
# ==========================================
echo -e "${BLUE}💿 DISCO${NC}"
echo "-------------------------------------------"
printf "%-20s %10s %10s %10s %10s %8s %s\n" "DISPOSITIVO" "TOTAL" "USADO" "LIVRE" "DISPONÍVEL" "USO%" "MONTAGEM"
echo "-------------------------------------------"
df -h | grep -E '^/dev/' | while read -r line; do
    device=$(echo "$line" | awk '{print $1}')
    size=$(echo "$line" | awk '{print $2}')
    used=$(echo "$line" | awk '{print $3}')
    avail=$(echo "$line" | awk '{print $4}')
    use_percent=$(echo "$line" | awk '{print $5}')
    mount=$(echo "$line" | awk '{print $6}')
    
    # Calcular livre (total - usado)
    # Pegar apenas números para cálculo
    use_num=$(echo "$use_percent" | sed 's/%//')
    
    # Cor baseada no uso
    if [ "$use_num" -gt 90 ]; then
        color="${RED}"
    elif [ "$use_num" -gt 80 ]; then
        color="${YELLOW}"
    else
        color="${GREEN}"
    fi
    
    printf "${color}%-20s %10s %10s %10s %10s %8s %s${NC}\n" \
        "$device" "$size" "$used" "$avail" "$avail" "$use_percent" "$mount"
done

# Resumo total
echo "-------------------------------------------"
TOTAL_SIZE=$(df -h --total | grep 'total' | awk '{print $2}')
TOTAL_USED=$(df -h --total | grep 'total' | awk '{print $3}')
TOTAL_AVAIL=$(df -h --total | grep 'total' | awk '{print $4}')
TOTAL_PERCENT=$(df -h --total | grep 'total' | awk '{print $5}')
echo -e "${BLUE}TOTAL:${NC}               $TOTAL_SIZE     $TOTAL_USED     $TOTAL_AVAIL     $TOTAL_AVAIL     $TOTAL_PERCENT"
echo ""

# ==========================================
# REDE
# ==========================================
echo -e "${BLUE}🌐 INTERFACES DE REDE${NC}"
echo "-------------------------------------------"
ip -br addr show | grep -v "lo" | awk '{printf "%-15s %s\n", $1, $3}'
echo ""

# ==========================================
# PROCESSOS TOP 5 CPU
# ==========================================
echo -e "${BLUE}🔝 TOP 5 PROCESSOS (CPU)${NC}"
echo "-------------------------------------------"
ps aux --sort=-%cpu | head -6 | tail -5 | awk '{printf "%-6s %5s%% %5s%% %-20s\n", $2, $3, $4, $11}'
echo ""

# ==========================================
# PROCESSOS TOP 5 MEMÓRIA
# ==========================================
echo -e "${BLUE}🔝 TOP 5 PROCESSOS (MEMÓRIA)${NC}"
echo "-------------------------------------------"
ps aux --sort=-%mem | head -6 | tail -5 | awk '{printf "%-6s %5s%% %5s%% %-20s\n", $2, $3, $4, $11}'
echo ""

# ==========================================
# DOCKER
# ==========================================
if command -v docker &> /dev/null; then
    echo -e "${BLUE}🐳 DOCKER${NC}"
    echo "-------------------------------------------"
    
    CONTAINERS_RUNNING=$(docker ps -q | wc -l)
    CONTAINERS_TOTAL=$(docker ps -aq | wc -l)
    IMAGES_TOTAL=$(docker images -q | wc -l)
    
    echo "Containers rodando: $CONTAINERS_RUNNING / $CONTAINERS_TOTAL"
    echo "Imagens: $IMAGES_TOTAL"
    echo ""
    
    echo "Uso de recursos Docker:"
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"
    echo ""
    
    echo "Espaço usado pelo Docker:"
    docker system df
    echo ""
fi

# ==========================================
# CONEXÕES DE REDE ATIVAS
# ==========================================
echo -e "${BLUE}🔌 CONEXÕES ATIVAS (PORTAS PRINCIPAIS)${NC}"
echo "-------------------------------------------"
netstat -tuln 2>/dev/null | grep -E ':(22|80|443|3000|5432|8080|9090|10050|10051)\s' | \
    awk '{printf "%-10s %-25s %s\n", $1, $4, $6}' || \
ss -tuln | grep -E ':(22|80|443|3000|5432|8080|9090|10050|10051)\s' | \
    awk '{printf "%-10s %-25s %s\n", $1, $5, $2}'
echo ""

# ==========================================
# TEMPERATURA (se disponível)
# ==========================================
if command -v sensors &> /dev/null; then
    echo -e "${BLUE}🌡️  TEMPERATURA${NC}"
    echo "-------------------------------------------"
    sensors | grep -E 'Core|temp' | head -5
    echo ""
fi

# ==========================================
# ÚLTIMOS LOGINS
# ==========================================
echo -e "${BLUE}👤 ÚLTIMOS LOGINS${NC}"
echo "-------------------------------------------"
last -n 5 | head -5
echo ""

# ==========================================
# SERVIÇOS IMPORTANTES
# ==========================================
echo -e "${BLUE}⚙️  SERVIÇOS IMPORTANTES${NC}"
echo "-------------------------------------------"
services=("docker" "ssh" "ufw")
for service in "${services[@]}"; do
    if systemctl is-active --quiet "$service"; then
        echo -e "${GREEN}✓${NC} $service: rodando"
    else
        echo -e "${RED}✗${NC} $service: parado"
    fi
done
echo ""

# ==========================================
# RESUMO DE ALERTAS
# ==========================================
echo "=========================================="
echo -e "${BLUE}📋 RESUMO DE ALERTAS${NC}"
echo "=========================================="

ALERTS=0

# Verificar CPU
if (( $(echo "$CPU_USAGE > 80" | bc -l) )); then
    echo -e "${RED}⚠️  CPU alto: ${CPU_USAGE}%${NC}"
    ((ALERTS++))
fi

# Verificar Memória
if (( $(echo "$MEM_PERCENT > 85" | bc -l) )); then
    echo -e "${RED}⚠️  Memória alta: ${MEM_PERCENT}%${NC}"
    ((ALERTS++))
fi

# Verificar Disco
while read -r line; do
    usage=$(echo "$line" | awk '{print $5}' | sed 's/%//')
    mount=$(echo "$line" | awk '{print $6}')
    if [ "$usage" -gt 85 ]; then
        echo -e "${RED}⚠️  Disco $mount: ${usage}% usado${NC}"
        ((ALERTS++))
    fi
done < <(df -h | grep -E '^/dev/')

if [ $ALERTS -eq 0 ]; then
    echo -e "${GREEN}✅ Sistema OK - Nenhum alerta${NC}"
fi

echo ""
echo "Relatório gerado em: $(date '+%Y-%m-%d %H:%M:%S')"
echo "=========================================="