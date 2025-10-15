#!/bin/bash
# Arquivo: ./scripts/quick-status.sh
# Status rápido do sistema

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Função para criar barra de progresso
progress_bar() {
    local percent=$1
    local width=30
    local filled=$((percent * width / 100))
    local empty=$((width - filled))
    
    printf "["
    printf "%${filled}s" | tr ' ' '█'
    printf "%${empty}s" | tr ' ' '░'
    printf "] %3d%%" "$percent"
}

# Função para cor baseada em valor
get_color() {
    local value=$1
    if [ "$value" -gt 85 ]; then
        echo "$RED"
    elif [ "$value" -gt 70 ]; then
        echo "$YELLOW"
    else
        echo "$GREEN"
    fi
}

clear
echo "╔════════════════════════════════════════════════════════════╗"
echo "║        🖥️  DASHBOARD DO SISTEMA - $(date '+%H:%M:%S')      ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# CPU
CPU_PERCENT=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 | cut -d'.' -f1)
CPU_COLOR=$(get_color $CPU_PERCENT)
echo -n "CPU:    "
echo -ne "${CPU_COLOR}"
progress_bar $CPU_PERCENT
echo -e "${NC}"

# Memória
MEM_PERCENT=$(free | awk '/^Mem:/ {printf "%.0f", $3/$2 * 100}')
MEM_COLOR=$(get_color $MEM_PERCENT)
echo -n "RAM:    "
echo -ne "${MEM_COLOR}"
progress_bar $MEM_PERCENT
echo -e "${NC}"

# Disco
DISK_PERCENT=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
DISK_COLOR=$(get_color $DISK_PERCENT)
echo -n "DISCO:  "
echo -ne "${DISK_COLOR}"
progress_bar $DISK_PERCENT
echo -e "${NC}"

echo ""
echo "┌────────────────────────────────────────────────────────────┐"
echo "│ DETALHES                                                   │"
echo "├────────────────────────────────────────────────────────────┤"

# CPU detalhes
LOAD_AVG=$(uptime | awk -F'load average:' '{print $2}' | xargs)
echo "│ 🔹 Load Average: $LOAD_AVG"

# Memória detalhes
MEM_USED=$(free -h | awk '/^Mem:/ {print $3}')
MEM_TOTAL=$(free -h | awk '/^Mem:/ {print $2}')
echo "│ 🔹 Memória: $MEM_USED / $MEM_TOTAL"

# Disco detalhes
DISK_USED=$(df -h / | tail -1 | awk '{print $3}')
DISK_TOTAL=$(df -h / | tail -1 | awk '{print $2}')
DISK_FREE=$(df -h / | tail -1 | awk '{print $4}')
echo "│ 🔹 Disco: $DISK_USED / $DISK_TOTAL (livre: $DISK_FREE)"

# Uptime
UPTIME=$(uptime -p)
echo "│ 🔹 Uptime: $UPTIME"

# Docker
if command -v docker &> /dev/null; then
    CONTAINERS=$(docker ps -q | wc -l)
    echo "│ 🔹 Containers: $CONTAINERS rodando"
fi

echo "└────────────────────────────────────────────────────────────┘"
echo ""

# Alertas
if [ "$CPU_PERCENT" -gt 85 ] || [ "$MEM_PERCENT" -gt 85 ] || [ "$DISK_PERCENT" -gt 85 ]; then
    echo -e "${RED}⚠️  ATENÇÃO: Recursos críticos!${NC}"
elif [ "$CPU_PERCENT" -gt 70 ] || [ "$MEM_PERCENT" -gt 70 ] || [ "$DISK_PERCENT" -gt 70 ]; then
    echo -e "${YELLOW}⚠️  Aviso: Recursos elevados${NC}"
else
    echo -e "${GREEN}✅ Sistema operando normalmente${NC}"
fi