# 📚 Documentação Completa - Stack Zabbix Enterprise

## 📋 Índice

1. [Visão Geral](#visão-geral)
2. [Arquitetura](#arquitetura)
3. [Estrutura de Arquivos](#estrutura-de-arquivos)
4. [Serviços](#serviços)
5. [Configuração](#configuração)
6. [Dashboards](#dashboards)
7. [Manutenção](#manutenção)
8. [Troubleshooting](#troubleshooting)
9. [Backup e Restore](#backup-e-restore)
10. [Monitoramento](#monitoramento)

---

## 🎯 Visão Geral

Stack completo de monitoramento enterprise com capacidade para **2.000-3.000 hosts simultâneos**.

### Componentes Principais:

| Componente | Versão | Porta | Função |
|------------|--------|-------|--------|
| Zabbix Server | 7.4 | 10051 | Core de monitoramento |
| Zabbix Web | 7.4 | 8080 | Interface web |
| Zabbix Agent 2 | 7.4 | 10050 | Agent local |
| PostgreSQL | 16-alpine | 5432 | Banco de dados |
| Grafana | latest | 3000 | Dashboards e visualização |
| Prometheus | latest | 9090 | Coleta de métricas |
| Node Exporter | latest | 9100 | Métricas do sistema |
| Postgres Exporter | latest | 9187 | Métricas do PostgreSQL |
| cAdvisor | latest | 8081 | Métricas dos containers |

### Recursos:

- ✅ Monitoramento de infraestrutura completo
- ✅ Dashboards profissionais no Grafana
- ✅ Alertas configurados no Prometheus
- ✅ Scripts de manutenção automatizados
- ✅ Backup automatizado
- ✅ Health checks
- ✅ Otimizado para alto volume

---

## 🏗️ Arquitetura

```
┌─────────────────────────────────────────────────────────────┐
│                    CAMADA DE APRESENTAÇÃO                   │
├─────────────────────────────────────────────────────────────┤
│  Zabbix Web (8080)          │         Grafana (3000)        │
│  - Interface principal      │  - Dashboards avançados       │
│  - Configuração hosts       │  - Visualizações              │
│  - Gestão de alertas        │  - Múltiplos datasources      │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    CAMADA DE PROCESSAMENTO                  │
├─────────────────────────────────────────────────────────────┤
│  Zabbix Server (10051)      │      Prometheus (9090)        │
│  - Coleta de dados          │  - Coleta métricas            │
│  - Processamento triggers   │  - Armazenamento TS           │
│  - Geração de alertas       │  - Regras de alerta           │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    CAMADA DE COLETA                         │
├─────────────────────────────────────────────────────────────┤
│  Zabbix Agent (10050)  │  Node Exporter (9100)              │
│  Postgres Exporter     │  cAdvisor (8081)                   │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    CAMADA DE DADOS                          │
├─────────────────────────────────────────────────────────────┤
│              PostgreSQL 16 Alpine (5432)                    │
│  - Dados Zabbix (otimizado)                                 │
│  - Dados Grafana (SQLite)                                   │
│  - Dados Prometheus (TSDB local)                            │
└─────────────────────────────────────────────────────────────┘
```

---

## 📁 Estrutura de Arquivos

```
zabbix-stack/
├── .env                          # Variáveis de ambiente
├── docker-compose.yml            # Definição dos serviços
│
├── grafana/                      # Configurações Grafana
│   ├── dashboards/              # Dashboards JSON
│   │   ├── postgres-monitoring.json     # Dashboard PostgreSQL
│   │   ├── zabbix.json                  # Dashboard Zabbix Stack
│   │   ├── docker-containers.json       # Dashboard Containers
│   │   └── nodeexporter.json            # Dashboard Sistema
│   └── provisioning/            # Provisioning automático (opcional)
│       ├── dashboards/          # Configuração de dashboards
│       └── datasources/         # Configuração de datasources
│
├── postgres/                     # Configurações PostgreSQL
│   └── backups/                 # Backups do banco (gerados automaticamente)
│
├── prometheus/                   # Configurações Prometheus
│   ├── prometheus.yml           # Configuração principal
│   └── alerts/                  # Regras de alerta
│       └── alerts.yml           # Definição de alertas
│
└── scripts/                      # Scripts de manutenção
    ├── backup.sh                # Backup automatizado
    ├── cleanup.sh               # Limpeza e manutenção (opcional)
    └── healthcheck.sh           # Verificação de saúde
```

**Nota:** A pasta `zabbix/` foi removida pois continha apenas subpastas vazias não utilizadas pelo stack.

---

## ⚙️ Serviços

### PostgreSQL
```yaml
Imagem: postgres:16-alpine
Hostname: postgres-zabbix
Porta: 5432
Recursos: 4 CPUs, 6GB RAM
Função: Banco de dados principal
```

**Otimizações:**
- `max_connections`: 300
- `shared_buffers`: 1GB
- `effective_cache_size`: 3GB
- `maintenance_work_mem`: 512MB
- `work_mem`: 10MB

### Zabbix Server
```yaml
Imagem: zabbix/zabbix-server-pgsql:alpine-7.4-latest
Hostname: zabbix-server
Porta: 10051
Recursos: 4 CPUs, 4GB RAM
Função: Core de monitoramento
```

**Otimizações:**
- `StartPollers`: 40
- `CacheSize`: 1G
- `HistoryCacheSize`: 512M
- `ValueCacheSize`: 512M
- `TrendCacheSize`: 256M

### Zabbix Web
```yaml
Imagem: zabbix/zabbix-web-nginx-pgsql:alpine-7.4-latest
Hostname: zabbix-web
Portas: 8080 (HTTP), 8443 (HTTPS)
Recursos: 2 CPUs, 1GB RAM
Função: Interface web
```

### Zabbix Agent 2
```yaml
Imagem: zabbix/zabbix-agent2:alpine-7.4-latest
Hostname: ${HOSTNAME} (do .env)
Porta: 10050
Função: Monitoramento local
```

### Grafana
```yaml
Imagem: grafana/grafana:latest
Hostname: grafana
Porta: 3000
Banco: SQLite (interno)
Função: Dashboards e visualizações
```

**Plugins Instalados:**
- alexanderzobnin-zabbix-app
- grafana-piechart-panel
- grafana-clock-panel

### Prometheus
```yaml
Imagem: prom/prometheus:latest
Hostname: prometheus
Porta: 9090
Retenção: 30 dias
Função: Coleta e armazenamento de métricas
```

### Node Exporter
```yaml
Imagem: prom/node-exporter:latest
Hostname: node-exporter
Porta: 9100
Função: Métricas do sistema operacional
```

### Postgres Exporter
```yaml
Imagem: prometheuscommunity/postgres-exporter:latest
Hostname: postgres-exporter
Porta: 9187
Função: Métricas do PostgreSQL
```

### cAdvisor
```yaml
Imagem: gcr.io/cadvisor/cadvisor:latest
Hostname: cadvisor
Porta: 8081
Função: Métricas dos containers Docker
```

---

## 🔧 Configuração

### Arquivo .env

```bash
# Domínio
DOMAIN=suaempresa.com.br

# Hostname do Zabbix Agent
HOSTNAME=zabbix-server-host

# PostgreSQL
DB_USER=zabbix
DB_PASSWORD=SenhaSuperSegura123

# Grafana
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=Admin@Grafana2025
```

### Primeiros Passos

1. **Clonar/Criar estrutura:**
```bash
mkdir -p ~/zabbix-stack
cd ~/zabbix-stack
```

2. **Criar pastas:**
```bash
mkdir -p grafana/{dashboards,provisioning/{datasources,dashboards}}
mkdir -p postgres/backups
mkdir -p prometheus/alerts
mkdir -p scripts
```

3. **Criar arquivos de configuração:**
```bash
# .env, docker-compose.yml, prometheus.yml, alerts.yml
# (usar os artefatos fornecidos)
```

4. **Dar permissões:**
```bash
chmod +x scripts/*.sh
chmod 755 postgres/backups
chmod 755 grafana/provisioning
```

5. **Subir o stack:**
```bash
docker compose up -d
```

6. **Verificar:**
```bash
docker compose ps
./scripts/healthcheck.sh
```

---

## 📊 Dashboards

### 1. PostgreSQL Monitoring
**Arquivo:** `grafana/dashboards/postgres-monitoring.json`

**Painéis:**
- Status do PostgreSQL (UP/DOWN)
- Conexões ativas
- Cache hit ratio
- Tamanho dos bancos
- Transações por segundo
- I/O do banco
- Operações (INSERT/UPDATE/DELETE/SELECT)
- TOP 10 maiores tabelas

**Datasource:** Prometheus

### 2. Zabbix Stack Overview
**Arquivo:** `grafana/dashboards/zabbix.json`

**Painéis:**
- Status dos serviços (Zabbix Server, Web, Agent, PostgreSQL)
- CPU usage por container
- Memory usage por container
- Network traffic
- Disk I/O
- Resource summary table

**Datasource:** Prometheus

### 3. Docker Containers Monitoring
**Arquivo:** `grafana/dashboards/docker-containers.json`

**Painéis:**
- CPU usage por container (%)
- Memory usage por container
- Network traffic (RX/TX)
- Disk I/O (Read/Write)
- Resource summary
- Memory distribution (pie chart)
- CPU distribution (pie chart)

**Datasource:** Prometheus

### 4. Sistema Operacional - Node Exporter
**Arquivo:** `grafana/dashboards/nodeexporter.json`

**Painéis:**
- CPU usage total (gauge)
- Memory usage (gauge)
- Disk usage (gauge)
- Uptime
- CPU por core
- Memory details
- Network traffic por interface
- Disk I/O por dispositivo
- System load average (1m, 5m, 15m)
- Filesystem usage (tabela)

**Datasource:** Prometheus

### Importar Dashboards

**Via Web UI:**
1. Grafana → **+ → Import**
2. Upload JSON ou cole o conteúdo
3. Selecione datasource **Prometheus**
4. **Import**

**Via Provisioning:**
```bash
# Dashboards são carregados automaticamente de:
grafana/dashboards/*.json
```

---

## 🔧 Manutenção

### Scripts Disponíveis

#### 1. healthcheck.sh
**Função:** Verificação completa de saúde do stack

**Uso:**
```bash
./scripts/healthcheck.sh
```

**O que verifica:**
- Status de todos os containers
- Portas em escuta
- Espaço em disco
- Uso de memória
- Volumes Docker
- Erros recentes nos logs
- Status do PostgreSQL
- Tamanho dos bancos
- Conexões ativas

**Executar:** Diariamente ou após mudanças

#### 2. cleanup.sh
**Função:** Limpeza e manutenção do banco

**Uso:**
```bash
./scripts/cleanup.sh
```

**O que faz:**
- VACUUM no PostgreSQL
- REINDEX (opcional)
- Limpar logs antigos dos containers
- Limpar imagens Docker não utilizadas
- Remover volumes órfãos
- Estatísticas das tabelas
- Verificar dead tuples
- Backup opcional antes da manutenção
- Rotação de backups (mantém 7 dias)

**Executar:** Semanalmente

#### 3. backup.sh
**Função:** Backup automatizado

**Uso:**
```bash
./scripts/backup.sh
```

**O que faz:**
- Backup do PostgreSQL (compactado)
- Backup das configurações do Grafana
- Rotação automática (30 dias)
- Verificação de integridade
- Estatísticas de espaço

**Executar:** Diariamente (automatizar com cron)

### Automatizar com Cron

```bash
# Editar crontab
crontab -e

# Adicionar linhas:
# Health check diário às 8h
0 8 * * * cd /caminho/para/zabbix-stack && ./scripts/healthcheck.sh >> /var/log/zabbix-health.log 2>&1

# Backup diário às 2h
0 2 * * * cd /caminho/para/zabbix-stack && ./scripts/backup.sh >> /var/log/zabbix-backup.log 2>&1

# Cleanup semanal (domingo às 3h)
0 3 * * 0 cd /caminho/para/zabbix-stack && ./scripts/cleanup.sh >> /var/log/zabbix-cleanup.log 2>&1
```

---

## 🚨 Troubleshooting

### Container não inicia

```bash
# Ver logs
docker logs <container_name>

# Ver últimas 50 linhas
docker logs <container_name> --tail 50

# Seguir logs em tempo real
docker logs -f <container_name>

# Verificar configuração
docker inspect <container_name>
```

### Zabbix Server não conecta ao banco

```bash
# Testar conexão
docker exec postgres-zabbix psql -U zabbix -d zabbix -c "SELECT version();"

# Verificar senha no .env
cat .env | grep DB_PASSWORD

# Ver logs do Zabbix Server
docker logs zabbix-server | grep -i error
```

### Grafana não mostra dados

```bash
# Verificar datasources
# Grafana → Configuration → Data Sources

# Testar no Explore
# Grafana → Explore → Prometheus → Query: up

# Verificar se Prometheus está coletando
curl http://localhost:9090/api/v1/targets
```

### Prometheus não coleta métricas

```bash
# Verificar config
docker exec prometheus cat /etc/prometheus/prometheus.yml

# Verificar targets
curl http://localhost:9090/api/v1/targets | jq

# Verificar se exporters estão respondendo
curl http://localhost:9100/metrics  # Node Exporter
curl http://localhost:9187/metrics  # Postgres Exporter
curl http://localhost:8081/metrics  # cAdvisor
```

### PostgreSQL lento

```bash
# Verificar queries lentas
docker exec postgres-zabbix psql -U zabbix -d zabbix -c "
  SELECT pid, now() - pg_stat_activity.query_start AS duration, query 
  FROM pg_stat_activity 
  WHERE state = 'active' 
    AND now() - pg_stat_activity.query_start > interval '5 seconds';"

# Verificar conexões
docker exec postgres-zabbix psql -U zabbix -d zabbix -c "
  SELECT count(*) as connections FROM pg_stat_activity;"

# Verificar cache hit ratio
docker exec postgres-zabbix psql -U zabbix -d zabbix -c "
  SELECT 
    sum(heap_blks_read) as heap_read,
    sum(heap_blks_hit) as heap_hit,
    sum(heap_blks_hit) / (sum(heap_blks_hit) + sum(heap_blks_read)) as ratio
  FROM pg_statio_user_tables;"
```

### Disco cheio

```bash
# Verificar uso de disco
df -h

# Verificar tamanho dos volumes Docker
docker system df -v

# Limpar recursos não utilizados
docker system prune -a --volumes

# Verificar tamanho dos bancos
docker exec postgres-zabbix psql -U zabbix -d zabbix -c "
  SELECT 
    pg_database.datname,
    pg_size_pretty(pg_database_size(pg_database.datname)) AS size
  FROM pg_database
  ORDER BY pg_database_size(pg_database.datname) DESC;"
```

### Container reiniciando constantemente

```bash
# Ver motivo do restart
docker inspect <container_name> | grep -A 10 State

# Ver últimos logs antes do crash
docker logs <container_name> --tail 100

# Ver eventos do container
docker events --filter container=<container_name>

# Verificar recursos disponíveis
free -h
df -h
```

### Alertas do Prometheus não funcionam

```bash
# Verificar regras de alerta
curl http://localhost:9090/api/v1/rules | jq

# Verificar alertas ativos
curl http://localhost:9090/api/v1/alerts | jq

# Validar arquivo de alertas
docker exec prometheus promtool check rules /etc/prometheus/alerts/alerts.yml

# Recarregar configuração
docker exec prometheus kill -HUP 1
```

---

## 💾 Backup e Restore

### Backup Manual

#### PostgreSQL
```bash
# Backup completo
docker exec postgres-zabbix pg_dump -U zabbix zabbix | gzip > backup_$(date +%Y%m%d).sql.gz

# Backup apenas schema
docker exec postgres-zabbix pg_dump -U zabbix --schema-only zabbix > schema_backup.sql

# Backup apenas dados
docker exec postgres-zabbix pg_dump -U zabbix --data-only zabbix > data_backup.sql

# Backup de tabela específica
docker exec postgres-zabbix pg_dump -U zabbix -t history zabbix > history_backup.sql
```

#### Grafana
```bash
# Backup do volume
docker run --rm \
  -v zabbix-stack_grafana_data:/data \
  -v $(pwd)/backups:/backup \
  alpine tar czf /backup/grafana_$(date +%Y%m%d).tar.gz -C /data .

# Backup via API (dashboards)
curl -H "Authorization: Bearer YOUR_API_KEY" \
  http://localhost:3000/api/search?type=dash-db | \
  jq -r '.[] | .uid' | \
  xargs -I {} curl -H "Authorization: Bearer YOUR_API_KEY" \
  http://localhost:3000/api/dashboards/uid/{} > dashboards_backup.json
```

#### Prometheus
```bash
# Backup do volume
docker run --rm \
  -v zabbix-stack_prometheus_data:/data \
  -v $(pwd)/backups:/backup \
  alpine tar czf /backup/prometheus_$(date +%Y%m%d).tar.gz -C /data .
```

#### Configurações
```bash
# Backup de todas as configurações
tar czf config_backup_$(date +%Y%m%d).tar.gz \
  .env \
  docker-compose.yml \
  grafana/ \
  prometheus/ \
  scripts/
```

### Restore

#### PostgreSQL
```bash
# Parar o Zabbix Server (para não ter conflitos)
docker stop zabbix-server

# Restore
gunzip < backup_20250112.sql.gz | docker exec -i postgres-zabbix psql -U zabbix zabbix

# Reiniciar serviços
docker start zabbix-server
```

#### Grafana
```bash
# Parar Grafana
docker stop grafana

# Restore
docker run --rm \
  -v zabbix-stack_grafana_data:/data \
  -v $(pwd)/backups:/backup \
  alpine sh -c "cd /data && tar xzf /backup/grafana_20250112.tar.gz"

# Iniciar Grafana
docker start grafana
```

#### Prometheus
```bash
# Parar Prometheus
docker stop prometheus

# Restore
docker run --rm \
  -v zabbix-stack_prometheus_data:/data \
  -v $(pwd)/backups:/backup \
  alpine sh -c "cd /data && tar xzf /backup/prometheus_20250112.tar.gz"

# Iniciar Prometheus
docker start prometheus
```

### Backup Automatizado com Cron

```bash
# Editar crontab
crontab -e

# Backup diário às 2h da manhã
0 2 * * * cd /caminho/para/zabbix-stack && ./scripts/backup.sh >> /var/log/zabbix-backup.log 2>&1

# Limpeza de backups antigos (manter 30 dias)
0 3 * * * find /caminho/para/zabbix-stack/postgres/backups -name "*.sql.gz" -mtime +30 -delete
```

### Backup para Servidor Remoto

```bash
#!/bin/bash
# backup-remote.sh

# Fazer backup local
./scripts/backup.sh

# Enviar para servidor remoto via rsync
rsync -avz --delete \
  postgres/backups/ \
  user@backup-server:/backups/zabbix/

# Ou via SCP
scp postgres/backups/zabbix_$(date +%Y%m%d).sql.gz \
  user@backup-server:/backups/zabbix/
```

---

## 📊 Monitoramento

### Métricas Importantes

#### Zabbix Server
```
Items/segundo processados
Triggers ativas
Hosts monitorados
Uso de cache
Fila de processamento
```

#### PostgreSQL
```
Conexões ativas / máximo
Cache hit ratio (deve ser >95%)
Transações/segundo
Tamanho do banco
Dead tuples (precisa VACUUM se alto)
Queries lentas
```

#### Sistema
```
CPU usage (deve estar <80%)
RAM usage (deve estar <85%)
Disk usage (deve estar <85%)
Load average (deve ser <num_cpus)
Network I/O
Disk I/O
```

#### Containers
```
CPU por container
RAM por container
Network I/O
Disk I/O
Status (UP/DOWN)
Restarts
```

### Limites e Thresholds

| Métrica | Warning | Critical | Ação |
|---------|---------|----------|------|
| CPU | >70% | >85% | Investigar processos |
| RAM | >75% | >90% | Adicionar memória |
| Disco | >80% | >90% | Limpar espaço |
| Conexões PG | >250 | >280 | Aumentar pool |
| Cache Hit PG | <90% | <85% | Aumentar shared_buffers |
| Load Average | >8 | >12 | Escalar recursos |

### Dashboards para Monitorar

1. **Dashboard Zabbix Stack** - Visão geral diária
2. **Dashboard PostgreSQL** - Verificar performance do banco
3. **Dashboard Containers** - Uso de recursos
4. **Dashboard Sistema** - Saúde do host

### Alertas Configurados

#### Prometheus Alerts (prometheus/alerts/alerts.yml)

**Sistema:**
- CPU alto (>80% por 5min)
- Memória alta (>85% por 5min)
- Disco baixo (<15% livre)

**Containers:**
- Container down (>2min)
- Container com CPU alto (>80% por 5min)
- Container com memória alta (>90% por 5min)

**PostgreSQL:**
- PostgreSQL down
- Conexões altas (>80%)
- Queries lentas (>5min)
- Banco grande (>50GB)

### Verificação Diária

```bash
# Executar health check
./scripts/healthcheck.sh

# Verificar se todos containers estão UP
docker compose ps

# Verificar alertas ativos no Prometheus
curl -s http://localhost:9090/api/v1/alerts | jq '.data.alerts[] | select(.state=="firing")'

# Verificar espaço em disco
df -h

# Verificar tamanho do banco Zabbix
docker exec postgres-zabbix psql -U zabbix -d zabbix -c "
  SELECT pg_size_pretty(pg_database_size('zabbix'));"
```

---

## 🔐 Segurança

### Senhas e Credenciais

**Armazenamento:**
- Todas as senhas no arquivo `.env`
- `.env` deve estar no `.gitignore`
- Nunca commitar senhas no Git

**Recomendações:**
```bash
# Gerar senha forte
openssl rand -base64 32

# Alterar senha PostgreSQL
docker exec -it postgres-zabbix psql -U zabbix
ALTER USER zabbix WITH PASSWORD 'nova_senha_forte';

# Alterar senha Zabbix Admin
# Via web UI: Administration → Users → Admin → Change password

# Alterar senha Grafana
docker exec grafana grafana-cli admin reset-admin-password nova_senha
```

### Firewall

```bash
# Instalar UFW (se não tiver)
sudo apt install ufw

# Regras básicas
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Permitir SSH
sudo ufw allow 22/tcp

# Portas do stack
sudo ufw allow 8080/tcp   # Zabbix Web
sudo ufw allow 3000/tcp   # Grafana
sudo ufw allow 9090/tcp   # Prometheus (apenas interno)
sudo ufw allow 10050/tcp  # Zabbix Agent (de qualquer host)
sudo ufw allow 10051/tcp  # Zabbix Server (de proxies)

# Ativar firewall
sudo ufw enable

# Ver status
sudo ufw status
```

### Acesso Externo

**Não expor diretamente:**
- ❌ PostgreSQL (5432)
- ❌ Prometheus (9090)
- ❌ Exporters (9100, 9187, 8081)

**Acesso via VPN ou Túnel SSH:**
```bash
# Túnel SSH para acessar Grafana
ssh -L 3000:localhost:3000 user@servidor

# Depois acessar http://localhost:3000 local
```

### SSL/TLS

**Opção 1: Traefik (recomendado para produção)**
- Reverse proxy com SSL automático
- Let's Encrypt integration
- Renovação automática

**Opção 2: Nginx Reverse Proxy**
```nginx
server {
    listen 443 ssl;
    server_name zabbix.empresa.com;

    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

---

## 📈 Escalabilidade

### Limites Atuais

**Configuração atual suporta:**
- ~2.000-3.000 hosts
- ~50.000-150.000 items
- ~5.000-15.000 NVPS

### Para Escalar Além

#### 1. Zabbix Proxies
```
Hosts remotos
    ↓
Zabbix Proxy (localidade 1)
    ↓
Zabbix Server (central) ← Zabbix Proxy (localidade 2)
```

**Benefícios:**
- Distribui carga
- Melhor para hosts remotos
- Tolerância a falhas de rede

#### 2. PostgreSQL Tuning
```yaml
# Aumentar recursos no docker-compose.yml
postgres:
  deploy:
    resources:
      limits:
        cpus: '8'
        memory: 16G
```

```bash
# Ajustar configurações
shared_buffers = 4GB
effective_cache_size = 12GB
```

#### 3. Zabbix Server Tuning
```yaml
# Aumentar workers
ZBX_STARTPOLLERS: 100
ZBX_CACHESIZE: 4G
ZBX_HISTORYCACHESIZE: 2G
```

#### 4. Hardware
```
CPU: 16+ cores
RAM: 32GB+
Disco: NVMe 1TB+
Network: 10Gbps
```

#### 5. Particionamento
```sql
-- Particionar tabelas grandes por data
-- history, trends, etc
```

#### 6. High Availability
```
Zabbix Server 1 (ativo)
Zabbix Server 2 (standby)
    ↓
PostgreSQL Primary
PostgreSQL Replica (streaming replication)
```

---

## 📚 Referências

### Documentação Oficial
- [Zabbix Documentation](https://www.zabbix.com/documentation/current/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)

### Recursos Úteis
- [Zabbix Templates](https://www.zabbix.com/integrations)
- [Grafana Dashboards](https://grafana.com/grafana/dashboards/)
- [Prometheus Exporters](https://prometheus.io/docs/instrumenting/exporters/)

### Comunidade
- [Zabbix Forum](https://www.zabbix.com/forum/)
- [Zabbix Brasil](https://www.zabbix.org/wiki/Zabbix_Brazilian_Community)
- [r/zabbix](https://reddit.com/r/zabbix)

---

## 📝 Changelog

### v1.0 - 2025-01-12
- ✅ Stack inicial com Zabbix 7.4
- ✅ PostgreSQL 16 Alpine otimizado
- ✅ Prometheus + Exporters completos
- ✅ 4 dashboards Grafana
- ✅ Scripts de manutenção
- ✅ Alertas configurados
- ✅ Documentação completa

---

## 📄 Licença

Este projeto é de uso livre para fins de monitoramento e administração de sistemas.

---

## 👥 Suporte

Para dúvidas ou problemas:
1. Verificar esta documentação
2. Executar `./scripts/healthcheck.sh`
3. Verificar logs: `docker compose logs -f`
4. Consultar troubleshooting acima

---

**Documentação criada em:** 12/01/2025  
**Última atualização:** 12/01/2025  
**Versão do Stack:** 1.0