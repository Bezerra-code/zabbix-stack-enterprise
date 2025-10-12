#!/bin/bash
# Arquivo: ./scripts/backup.sh
# Backup automatizado do PostgreSQL

set -e

# Configurações
BACKUP_DIR="./postgres/backups"
RETENTION_DAYS=30
DATE=$(date +%Y%m%d_%H%M%S)

# Cores
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo "=========================================="
echo "💾 BACKUP - Zabbix Stack"
echo "=========================================="
echo ""

# Criar diretório de backup se não existir
mkdir -p $BACKUP_DIR

# ==========================================
# BACKUP DO POSTGRESQL
# ==========================================
echo "📦 Fazendo backup do PostgreSQL..."

BACKUP_FILE="$BACKUP_DIR/zabbix_${DATE}.sql.gz"

# Executar backup
if docker exec postgres-zabbix pg_dump -U zabbix zabbix | gzip > $BACKUP_FILE; then
    BACKUP_SIZE=$(du -h "$BACKUP_FILE" | awk '{print $1}')
    echo -e "${GREEN}✓${NC} Backup criado com sucesso!"
    echo "  Arquivo: $BACKUP_FILE"
    echo "  Tamanho: $BACKUP_SIZE"
else
    echo -e "${RED}✗${NC} Erro ao criar backup!"
    exit 1
fi

echo ""

# ==========================================
# BACKUP DO GRAFANA (CONFIGURAÇÕES)
# ==========================================
echo "📊 Fazendo backup das configurações do Grafana..."

GRAFANA_BACKUP="$BACKUP_DIR/grafana_${DATE}.tar.gz"

if docker run --rm \
    -v zabbix-stack_grafana_data:/data \
    -v $(pwd)/$BACKUP_DIR:/backup \
    alpine tar czf /backup/grafana_${DATE}.tar.gz -C /data .; then
    GRAFANA_SIZE=$(du -h "$GRAFANA_BACKUP" | awk '{print $1}')
    echo -e "${GREEN}✓${NC} Backup do Grafana criado!"
    echo "  Arquivo: $GRAFANA_BACKUP"
    echo "  Tamanho: $GRAFANA_SIZE"
else
    echo -e "${RED}✗${NC} Erro ao criar backup do Grafana!"
fi

echo ""

# ==========================================
# ROTAÇÃO DE BACKUPS
# ==========================================
echo "🔄 Rotação de backups (mantendo últimos $RETENTION_DAYS dias)..."

# Remover backups antigos
DELETED=$(find $BACKUP_DIR -name "zabbix_*.sql.gz" -type f -mtime +$RETENTION_DAYS -delete -print | wc -l)
DELETED_GRAFANA=$(find $BACKUP_DIR -name "grafana_*.tar.gz" -type f -mtime +$RETENTION_DAYS -delete -print | wc -l)

echo "  Backups PostgreSQL removidos: $DELETED"
echo "  Backups Grafana removidos: $DELETED_GRAFANA"

# Contar backups restantes
TOTAL_BACKUPS=$(find $BACKUP_DIR -name "zabbix_*.sql.gz" -type f | wc -l)
TOTAL_SPACE=$(du -sh $BACKUP_DIR | awk '{print $1}')

echo ""
echo "📈 Estatísticas:"
echo "  Total de backups: $TOTAL_BACKUPS"
echo "  Espaço utilizado: $TOTAL_SPACE"

echo ""

# ==========================================
# VERIFICAR INTEGRIDADE
# ==========================================
echo "🔍 Verificando integridade do backup..."

if gunzip -t "$BACKUP_FILE" 2>/dev/null; then
    echo -e "${GREEN}✓${NC} Backup íntegro e válido"
else
    echo -e "${RED}✗${NC} ATENÇÃO: Backup pode estar corrompido!"
fi

echo ""
echo "=========================================="
echo -e "${GREEN}✅ BACKUP CONCLUÍDO COM SUCESSO${NC}"
echo "=========================================="
echo ""
echo "Data: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# ==========================================
# INSTRUÇÕES DE RESTORE
# ==========================================
cat << 'EOF'
📝 Para restaurar o backup:

PostgreSQL:
  gunzip < zabbix_YYYYMMDD_HHMMSS.sql.gz | docker exec -i postgres-zabbix psql -U zabbix zabbix

Grafana:
  docker run --rm -v zabbix-stack_grafana_data:/data -v $(pwd)/postgres/backups:/backup alpine tar xzf /backup/grafana_YYYYMMDD_HHMMSS.tar.gz -C /data

EOF