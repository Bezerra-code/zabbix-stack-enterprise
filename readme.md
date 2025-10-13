# 📚 Stack Zabbix Enterprise - Documentação Completa

## 📋 Índice

1. [Visão Geral](#-visão-geral)
2. [Arquitetura](#️-arquitetura)
3. [Instalação Rápida](#-instalação-rápida)
4. [Estrutura de Arquivos](#-estrutura-de-arquivos)
5. [Serviços](#️-serviços)
6. [Configuração de Rede](#-configuração-de-rede)
7. [Adicionar Hosts](#-adicionar-hosts-para-monitorar)
8. [Dashboards Grafana](#-dashboards-grafana)
9. [Manutenção](#-manutenção)
10. [Troubleshooting](#-troubleshooting)
11. [Backup e Restore](#-backup-e-restore)
12. [Segurança](#-segurança)
13. [Ambientes Corporativos](#-ambientes-corporativos)

---

## 🎯 Visão Geral

Stack completo de monitoramento enterprise com capacidade para **2.000-3.000 hosts simultâneos**.

### Componentes Principais:

| Componente | Versão | Porta Externa | Função |
|------------|--------|---------------|--------|
| Zabbix Server | 7.4 | 10051 | Core de monitoramento |
| Zabbix Web | 7.4 | 8080 | Interface web |
| Zabbix Agent 2 | 7.4 | 10060 | Agent local (container) |
| PostgreSQL | 16-alpine | 5432* | Banco de dados |
| Grafana | latest | 3000 | Dashboards e visualização |
| Prometheus | latest | 9090 | Coleta de métricas |
| Node Exporter | latest | 9100 | Métricas do sistema |
| Postgres Exporter | latest | 9187 | Métricas do PostgreSQL |
| cAdvisor | latest | 8081 | Métricas dos containers |

**\*Apenas interno** por padrão (não exposto externamente)

### Recursos:

- ✅ Setup wizard automático com detecção de rede
- ✅ Monitoramento de infraestrutura completo
- ✅ Dashboards profissionais no Grafana
- ✅ Alertas configurados no Prometheus
- ✅ Scripts de manutenção automatizados
- ✅ Backup automatizado
- ✅ Health checks
- ✅ Otimizado para alto volume
- ✅ Suporte a múltiplas VLANs/redes

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
│  Zabbix Agent (10060)  │  Node Exporter (9100)              │
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

## 🚀 Instalação Rápida

### Pré-requisitos

```bash
# Ubuntu/Debian
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# Logout e login novamente
```

### Setup Wizard (Recomendado)

```bash
# 1. Clone o repositório
git clone <seu-repo> zabbix-stack
cd zabbix-stack

# 2. Execute o wizard de configuração
chmod +x setup.sh
./setup.sh
```

**O wizard irá:**
- ✅ Detectar seu ambiente (Linux, WSL, macOS)
- ✅ Descobrir IPs disponíveis automaticamente
- ✅ Oferecer 3 modos de configuração:
  - **Rápido:** Detecção automática completa
  - **Avançado:** Controle manual de todas opções
  - **Desenvolvimento:** Apenas localhost
- ✅ Gerar senhas fortes automaticamente
- ✅ Criar arquivo `.env` configurado
- ✅ Gerar templates de configuração dos agents
- ✅ Criar estrutura de pastas
- ✅ Inicializar o stack completo

### Primeiro Acesso

**Zabbix Web:** `http://SEU_IP:8080`
- Usuário: `Admin`
- Senha: `zabbix` ⚠️ **TROCAR IMEDIATAMENTE!**

**Grafana:** `http://SEU_IP:3000`
- Usuário: `admin`
- Senha: (verificar em `.env`)

---

## 📁 Estrutura de Arquivos

```
zabbix-stack/
├── setup.sh                      # ⭐ Wizard de configuração
├── validate-agent.sh             # ⭐ Validador de agents
├── .env                          # Configuração (gerado pelo setup.sh)
├── .env.example                  # Template de configuração
├── .gitignore                    # Proteção de senhas
├── docker-compose.yml            # Definição dos serviços
├── README.md                     # Esta documentação
├── QUICKSTART.md                 # Guia de início rápido
│
├── grafana/
│   ├── dashboards/              # Dashboards JSON
│   │   ├── postgres-monitoring.json
│   │   ├── zabbix.json
│   │   ├── docker-containers.json
│   │   └── nodeexporter.json
│   └── provisioning/            # Configuração automática
│       ├── datasources/
│       │   └── prometheus.yml
│       └── dashboards/
│
├── postgres/
│   ├── init/                    # Scripts de inicialização
│   │   └── 01-create-monitoring-user.sh
│   └── backups/                 # Backups (gerados)
│
├── prometheus/
│   ├── prometheus.yml           # Configuração principal
│   └── alerts/
│       └── alerts.yml           # Regras de alerta
│
└── scripts/
    ├── backup.sh                # Backup automatizado
    ├── cleanup.sh               # Manutenção
    └── healthcheck.sh           # Verificação de saúde
```

---

## ⚙️ Serviços

### PostgreSQL
```yaml
Imagem: postgres:16-alpine
Porta: 5432 (apenas interna)
Recursos: 4 CPUs, 6GB RAM
Otimizações: max_connections=300, shared_buffers=1GB
```

### Zabbix Server
```yaml
Imagem: zabbix/zabbix-server-pgsql:alpine-7.4-latest
Porta: 10051 (exposta para agents externos)
Recursos: 4 CPUs, 4GB RAM
Otimizações: StartPollers=40, CacheSize=1G
```

### Zabbix Agent 2 (Container)
```yaml
Imagem: zabbix/zabbix-agent2:alpine-7.4-latest
Porta: 10060 (externa) → 10050 (interna)
Função: Monitorar o servidor onde o Docker está rodando
Acesso: Volumes /proc, /sys, / montados para ler métricas do host
```

**⚠️ IMPORTANTE:** A porta externa é **10060** para não conflitar com agents externos que usam 10050.

### Outros Serviços
Ver seção completa no arquivo original ou usar `docker compose ps`

---

## 🌐 Configuração de Rede

### Variáveis de Ambiente (.env)

O arquivo `.env` é criado automaticamente pelo `setup.sh`, mas você pode configurar manualmente:

```bash
# IP do servidor (AUTO para detecção automática)
SERVER_IP=AUTO

# Interface de bind (0.0.0.0 = todas interfaces)
BIND_INTERFACE=0.0.0.0

# Portas
ZABBIX_SERVER_PORT=10051
ZABBIX_WEB_PORT=8080
GRAFANA_PORT=3000

# Subnet Docker (não alterar sem necessidade)
DOCKER_SUBNET=172.20.0.0/16
```

### Detecção Automática de Rede

O `setup.sh` detecta automaticamente:
- IPs físicos da rede (ex: 192.168.1.100)
- IPs WSL (ex: 172.22.187.36)
- IPs Docker (ex: 172.20.0.1)

E configura o stack para ser acessível de outras máquinas na rede.

### Portas Expostas

| Serviço | Porta | Bind | Finalidade |
|---------|-------|------|------------|
| Zabbix Server | 10051 | 0.0.0.0 | Agents externos |
| Zabbix Web | 8080 | 0.0.0.0 | Interface web |
| Zabbix Agent | 10060 | 0.0.0.0 | Monitoramento local |
| Grafana | 3000 | 0.0.0.0 | Dashboards |
| Prometheus | 9090 | 0.0.0.0 | Métricas (recomendado apenas interno) |
| PostgreSQL | 5432 | Não exposto | Apenas containers |

---

## 🖥️ Adicionar Hosts para Monitorar

### Configuração de Agents

O `setup.sh` gera automaticamente os templates:
- `agent-config-linux.conf` - Para hosts Linux
- `agent-config-windows.conf` - Para hosts Windows

Os templates já vêm com o **IP correto** do servidor!

### Linux (Ubuntu/Debian)

```bash
# 1. Instalar agent
wget https://repo.zabbix.com/zabbix/7.4/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest_7.4+ubuntu22.04_all.deb
sudo dpkg -i zabbix-release_latest_7.4+ubuntu22.04_all.deb
sudo apt update
sudo apt install zabbix-agent2 -y

# 2. Usar template gerado pelo setup.sh
sudo cp agent-config-linux.conf /etc/zabbix/zabbix_agent2.conf

# 3. IMPORTANTE: Editar e alterar Hostname
sudo nano /etc/zabbix/zabbix_agent2.conf
# Alterar: Hostname=ALTERE_PARA_NOME_UNICO
# Para: Hostname=servidor-web-01

# 4. Iniciar
sudo systemctl restart zabbix-agent2
sudo systemctl enable zabbix-agent2

# 5. Liberar firewall
sudo ufw allow 10050/tcp

# 6. Testar
zabbix_agent2 -t agent.ping
```

### Windows

```powershell
# 1. Baixar agent
# https://www.zabbix.com/download_agents
# Escolher: Windows 64-bit

# 2. Instalar MSI como Administrador

# 3. Usar template gerado pelo setup.sh
# Copiar conteúdo de: agent-config-windows.conf
# Colar em: C:\Program Files\Zabbix Agent 2\zabbix_agent2.conf

# 4. IMPORTANTE: Editar e alterar Hostname
notepad "C:\Program Files\Zabbix Agent 2\zabbix_agent2.conf"
# Alterar: Hostname=ALTERE_PARA_NOME_UNICO
# Para: Hostname=desktop-vendas-01

# 5. Liberar firewall
New-NetFirewallRule -DisplayName "Zabbix Agent 2" -Direction Inbound -Protocol TCP -LocalPort 10050 -Action Allow

# 6. Reiniciar serviço
Restart-Service "Zabbix Agent 2"
Get-Service "Zabbix Agent 2"
```

### Validar Agent

Use o script validador:

```bash
chmod +x validate-agent.sh
./validate-agent.sh

# Escolha:
# 1) Validar agent remoto via SSH (Linux)
# 2) Testar conectividade de qualquer host
```

### Adicionar no Zabbix Web

```
1. Acessar: http://SEU_IP:8080
2. Data collection → Hosts → Create host

Configuração:
┌─────────────────────────────────────┐
│ Host name: servidor-web-01          │
│ Templates:                          │
│   Linux: Linux by Zabbix agent active│
│   Windows: Windows by Zabbix agent active│
│ Host groups:                        │
│   Linux: Linux servers              │
│   Windows: Windows servers          │
│                                     │
│ Interfaces:                         │
│   Type: Agent                       │
│   IP address: 192.168.1.101         │
│   Port: 10050                       │
└─────────────────────────────────────┘

3. Add
4. Aguardar 1-2 minutos
5. Verificar coluna "Availability" → ZBX verde ✅
```

### Hosts Especiais

#### Monitorar o Próprio Servidor Zabbix

```
Host name: zabbix-server
Interface: zabbix-agent:10050 (DNS name)
Template: Linux by Zabbix agent active
```

**OU via IP:**
```
Interface: SEU_IP:10060 (porta externa do container)
```

---

## 📊 Dashboards Grafana

### Configurar Datasources

**1. Prometheus** (automático via provisioning)
- Já vem configurado
- URL: `http://prometheus:9090`

**2. Zabbix** (manual)
```
Grafana → Configuration → Data Sources → Add data source
Escolher: Zabbix

URL: http://zabbix-web:8080/api_jsonrpc.php
Username: Admin
Password: zabbix

Save & Test
```

### Dashboards Incluídos

1. **PostgreSQL Monitoring** - Métricas detalhadas do banco
2. **Zabbix Stack Overview** - Status de todos serviços
3. **Docker Containers** - Uso de recursos dos containers
4. **Node Exporter** - Métricas do sistema operacional

### Importar Dashboards

**Via UI:**
```
+ → Import → Upload JSON
Selecionar datasource (Prometheus ou Zabbix)
Import
```

**Via Provisioning (Automático):**
Os dashboards em `grafana/dashboards/*.json` são carregados automaticamente!

---

## 🔧 Manutenção

### Scripts Disponíveis

```bash
# Health check completo
./scripts/healthcheck.sh

# Backup manual
./scripts/backup.sh

# Limpeza e manutenção do banco
./scripts/cleanup.sh
```

### Automatizar com Cron

```bash
crontab -e

# Health check diário às 8h
0 8 * * * cd /caminho/para/zabbix-stack && ./scripts/healthcheck.sh >> /var/log/zabbix-health.log 2>&1

# Backup diário às 2h
0 2 * * * cd /caminho/para/zabbix-stack && ./scripts/backup.sh >> /var/log/zabbix-backup.log 2>&1

# Cleanup semanal (domingo às 3h)
0 3 * * 0 cd /caminho/para/zabbix-stack && ./scripts/cleanup.sh >> /var/log/zabbix-cleanup.log 2>&1
```

### Comandos Úteis

```bash
# Ver status
docker compose ps

# Ver logs
docker compose logs -f

# Reiniciar serviço específico
docker compose restart zabbix-server

# Parar tudo
docker compose down

# Atualizar stack
docker compose pull
docker compose up -d
```

---

## 🚨 Troubleshooting

### Container não inicia

```bash
docker logs <container_name>
docker logs <container_name> --tail 50
docker logs -f <container_name>
```

### Zabbix Server não conecta ao banco

```bash
docker exec postgres-zabbix psql -U zabbix -d zabbix -c "SELECT version();"
docker logs zabbix-server | grep -i error
```

### Agent não conecta (Availability vermelho)

```bash
# No host com agent:
zabbix_agent2 -t agent.ping

# No servidor Zabbix:
docker exec zabbix-server zabbix_get -s IP_DO_HOST -k agent.ping

# Verificar firewall
sudo ufw status | grep 10050  # Linux
Get-NetFirewallRule -DisplayName "Zabbix Agent 2"  # Windows

# Ver logs
sudo tail -f /var/log/zabbix/zabbix_agent2.log  # Linux
notepad "C:\Program Files\Zabbix Agent 2\zabbix_agent2.log"  # Windows
```

### Grafana não mostra dados

```bash
# Verificar datasources
# Grafana → Configuration → Data Sources

# Testar conexão Prometheus
curl http://localhost:9090/api/v1/targets

# Ver targets
curl http://localhost:9090/api/v1/targets | jq
```

### Conflito de Porta 10050

Se você receber erro "Address already in use" na porta 10050:

```bash
# Ver o que está usando
sudo ss -tulpn | grep 10050

# Parar agent do sistema (se houver)
sudo systemctl stop zabbix-agent2
sudo systemctl disable zabbix-agent2

# O container zabbix-agent usa porta 10060 externa
# para não conflitar com agents externos
```

---

## 💾 Backup e Restore

### Backup Automático

```bash
# Executar backup
./scripts/backup.sh

# O script faz backup de:
# - PostgreSQL (compactado)
# - Grafana (configurações)
# - Rotação automática (30 dias)
```

### Backup Manual

```bash
# PostgreSQL
docker exec postgres-zabbix pg_dump -U zabbix zabbix | gzip > backup_$(date +%Y%m%d).sql.gz

# Grafana
docker run --rm \
  -v zabbix-stack_grafana_data:/data \
  -v $(pwd)/backups:/backup \
  alpine tar czf /backup/grafana_$(date +%Y%m%d).tar.gz -C /data .

# Configurações
tar czf config_backup_$(date +%Y%m%d).tar.gz \
  .env docker-compose.yml grafana/ prometheus/ scripts/
```

### Restore

```bash
# Parar Zabbix Server
docker stop zabbix-server

# Restore PostgreSQL
gunzip < backup_20250113.sql.gz | docker exec -i postgres-zabbix psql -U zabbix zabbix

# Reiniciar
docker start zabbix-server
```

---

## 🔐 Segurança

### ⚠️ CRÍTICO: Proteção de Senhas

**NUNCA commite o arquivo `.env` no Git!**

O `.env` contém todas as senhas e está protegido pelo `.gitignore`.

```bash
# Verificar antes de commitar
git check-ignore .env
# Deve retornar: .env

# Verificar o que será commitado
git status
# .env NÃO deve aparecer!
```

### Trocar Senhas Padrão

**1. Zabbix (IMEDIATAMENTE após instalação):**
```
Administration → Users → Admin → Change password
```

**2. Grafana:**
Senha já definida no `.env` durante o setup

**3. PostgreSQL:**
```bash
docker exec -it postgres-zabbix psql -U zabbix
ALTER USER zabbix WITH PASSWORD 'nova_senha_forte';
\q

# Atualizar .env
nano .env
# Alterar: DB_PASSWORD=nova_senha_forte

# Reiniciar serviços
docker compose restart zabbix-server postgres-exporter
```

### Firewall

```bash
# Portas necessárias
sudo ufw allow 22/tcp      # SSH
sudo ufw allow 10051/tcp   # Zabbix Server (agents)
sudo ufw allow 8080/tcp    # Zabbix Web
sudo ufw allow 3000/tcp    # Grafana

# NÃO expor
# 5432  - PostgreSQL
# 9090  - Prometheus
# 9100, 9187, 8081 - Exporters

sudo ufw enable
sudo ufw status
```

### Restringir Acesso por IP

```bash
# Permitir apenas rede corporativa
sudo ufw allow from 192.168.1.0/24 to any port 8080
sudo ufw allow from 192.168.1.0/24 to any port 3000

# Ou IPs específicos
sudo ufw allow from 192.168.1.50 to any port 8080
```

---

## 🏢 Ambientes Corporativos

### Configuração Multi-VLAN

Em ambientes com múltiplas VLANs, o Zabbix Server precisa de:

1. **IP Roteável**: Acessível de todas as VLANs
2. **Porta 10051 Exposta**: Em todas as interfaces
3. **Regras de Firewall**: Permitindo porta 10051 das VLANs autorizadas

**Exemplo:**
```
Servidor Zabbix: 10.10.10.100 (VLAN Gerência)
         ↓
    Firewall/Switch Core
    (Roteamento configurado)
         ↓
VLAN 20 - Servidores (10.10.20.0/24)
VLAN 30 - Desktops (10.10.30.0/24)
VLAN 40 - DMZ (10.10.40.0/24)
```

**Todos os agents apontam para:** `Server=10.10.10.100`

### Firewall Corporativo

```bash
# No servidor Zabbix
sudo ufw allow from 10.10.20.0/24 to any port 10051 comment "VLAN Servidores"
sudo ufw allow from 10.10.30.0/24 to any port 10051 comment "VLAN Desktops"
sudo ufw allow from 10.10.40.0/24 to any port 10051 comment "VLAN DMZ"

# Acesso web apenas da gerência
sudo ufw allow from 10.10.10.0/24 to any port 8080
sudo ufw allow from 10.10.10.0/24 to any port 3000
```

### Organização no Zabbix Web

**Host Groups por VLAN:**
```
├── VLAN 10 - Gerência
├── VLAN 20 - Servidores
├── VLAN 30 - Desktops
└── VLAN 40 - DMZ
```

**Host Groups por Função:**
```
├── Linux Servers
├── Windows Servers
├── Network Devices
└── Web Servers
```

---

## 🐧 Ambiente WSL2 - Notas Especiais

### Porta do zabbix-agent Container

O container `zabbix-agent` usa porta **10060** externamente para evitar conflito com agents Windows em ambientes WSL2.

```yaml
zabbix-agent:
  ports:
    - "10060:10050"  # Externa:Interna
```

### Networking Nativo WSL2

Em ambientes WSL2 modernos (Windows 11 + Docker Desktop recente), o Zabbix Server consegue acessar diretamente o IP do Windows na interface WSL sem necessidade de port forwarding.

**Configuração:**
- Windows Agent: `Server=172.22.X.X` (IP do WSL)
- Zabbix Web: Interface → `172.22.176.1:10050` (IP do Windows)
- Funciona nativamente! ✅

### Para Produção (Servidor Ubuntu Real)

Você pode voltar a porta para 10050:

```yaml
zabbix-agent:
  ports:
    - "10050:10050"
```

---

## 📚 Referências

- [Zabbix Documentation](https://www.zabbix.com/documentation/current/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Docker Documentation](https://docs.docker.com/)

---

## 📝 Changelog

### v1.1 - 2025-01-13
- ✅ Setup wizard com detecção automática de rede
- ✅ Script de validação de agents
- ✅ Templates de configuração gerados automaticamente
- ✅ Porta do zabbix-agent alterada para 10060 (WSL compatibility)
- ✅ Suporte a ambientes multi-VLAN documentado
- ✅ Documentação completa atualizada

### v1.0 - 2025-01-12
- ✅ Stack inicial com Zabbix 7.4
- ✅ PostgreSQL 16 Alpine otimizado
- ✅ Prometheus + Exporters completos
- ✅ 4 dashboards Grafana
- ✅ Scripts de manutenção automatizados
- ✅ Alertas Prometheus configurados

---

## 🆘 Suporte

Para dúvidas ou problemas:
1. Ver `QUICKSTART.md` para início rápido
2. Executar `./scripts/healthcheck.sh`
3. Executar `./validate-agent.sh` para problemas com agents
4. Verificar logs: `docker compose logs -f`
5. Consultar seção Troubleshooting neste README

---

## 📄 Licença

Este projeto é de uso livre para fins de monitoramento e administração de sistemas.

---

**Documentação atualizada em:** 13/01/2025  
**Versão do Stack:** 1.1