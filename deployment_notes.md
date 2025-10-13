# 📝 Notas de Deploy - Stack Zabbix Enterprise

## 🎯 Configurações Validadas

### Ambiente de Desenvolvimento (WSL2)

**Características:**
- Windows 11 + WSL2 + Docker Desktop
- Networking nativo WSL2 (sem port forwarding necessário!)
- Container `zabbix-agent` na porta **10060** (evita conflito)

**Configuração:**
```yaml
zabbix-agent:
  ports:
    - "10060:10050"  # Porta externa diferente
```

**Por quê?**
- Porta 10050 no WSL fica livre para agents externos (Windows, etc)
- WSL2 moderno permite containers acessarem Windows diretamente via `172.22.176.1`
- Não precisa de socat/port forwarding!

---

### Ambiente de Produção (Ubuntu Server)

**Características:**
- Servidor Ubuntu dedicado
- IP fixo e roteável
- Sem WSL, networking simples

**Configuração:**
```yaml
zabbix-agent:
  ports:
    - "10050:10050"  # Pode usar porta padrão
```

**Por quê?**
- Não há conflito de portas
- Agents externos acessam diretamente o IP do servidor
- Arquitetura mais simples

---

## 🔑 Descobertas Importantes

### 1. Conflito de Porta 10050

**Problema:**
```
Error: bind(5, {AF=2 172.22.187.36:10050}, 16): Address already in use
```

**Causa:**
Container `zabbix-agent` e agents externos tentando usar mesma porta.

**Solução:**
Alterar porta externa do container para 10060.

---

### 2. Networking WSL2 Nativo

**Descoberta:**
Containers Docker no WSL2 conseguem acessar **diretamente** o IP do Windows (`172.22.176.1`) sem configuração adicional!

**Validação:**
```bash
docker exec zabbix-server zabbix_get -s 172.22.176.1 -k agent.ping
# Retorna: 1 ✅
```

**Implicação:**
Em Windows 11 + WSL2 recente, não precisa de port forwarding para monitorar o host Windows!

---

### 3. IPs Relevantes

**Em ambiente WSL:**
- `172.22.176.1` - Windows (interface WSL)
- `172.22.187.36` - WSL Ubuntu (eth0)
- `172.20.0.0/16` - Rede Docker interna
- `172.17.0.1` - Docker bridge padrão

**Qual usar?**
- Agents externos → IP do WSL (`172.22.187.36`)
- Agents internos → DNS do container (`zabbix-agent`)
- Windows → IP direto (`172.22.176.1`)

---

### 4. Setup Wizard

**Funcionalidades:**
- Detecção automática de IPs
- 3 modos de configuração (Rápido/Avançado/Dev)
- Geração de senhas fortes
- Templates de agents pré-configurados
- Criação automática de `.env`

**Benefício:**
Deploy em qualquer ambiente com **ZERO** configuração manual de rede!

---

## 📊 Arquitetura Validada

### Hosts Monitorados

| Host | Interface | Porta | Método |
|------|-----------|-------|--------|
| **zabbix-server** (local) | `zabbix-agent:10050` | 10050 | DNS interno Docker |
| **windows-host** | `172.22.176.1:10050` | 10050 | Networking nativo WSL2 |
| **hosts-externos** | `IP_HOST:10050` | 10050 | Rede corporativa |

### Portas Expostas

| Serviço | Porta Externa | Porta Interna | Bind |
|---------|---------------|---------------|------|
| Zabbix Server | 10051 | 10051 | 0.0.0.0 |
| Zabbix Web | 8080 | 8080 | 0.0.0.0 |
| Zabbix Agent | **10060** | 10050 | 0.0.0.0 |
| Grafana | 3000 | 3000 | 0.0.0.0 |
| Prometheus | 9090 | 9090 | 0.0.0.0 |
| PostgreSQL | - | 5432 | Interno |

---

## ⚠️ Problemas Comuns e Soluções

### 1. "Address already in use" na porta 10050

**Causa:** Agent instalado no sistema ou container usando mesma porta.

**Solução:**
```bash
# Parar agent do sistema
sudo systemctl stop zabbix-agent2

# OU alterar porta do container para 10060
ports:
  - "10060:10050"
```

---

### 2. Agent não conecta (Availability vermelho)

**Checklist:**
- [ ] Agent rodando? `systemctl status zabbix-agent2`
- [ ] Server= correto no agent? Verificar IP
- [ ] Firewall liberado? `ufw allow 10050/tcp`
- [ ] Conectividade OK? `zabbix_get -s IP -k agent.ping`
- [ ] Hostname único? Não pode repetir

**Debug:**
```bash
# Logs do agent
sudo tail -f /var/log/zabbix/zabbix_agent2.log

# Testar do servidor
docker exec zabbix-server zabbix_get -s IP_HOST -k agent.ping
```

---

### 3. Grafana sem dados do Zabbix

**Causa:** Datasource não configurado.

**Solução:**
```
Configuration → Data Sources → Add data source → Zabbix
URL: http://zabbix-web:8080/api_jsonrpc.php
Username: Admin
Password: zabbix
Save & Test
```

---

## 🔐 Segurança

### Checklist Essencial

- [ ] Trocar senha padrão do Zabbix (`Admin`/`zabbix`)
- [ ] `.env` protegido (no `.gitignore`)
- [ ] Firewall configurado (apenas portas necessárias)
- [ ] PostgreSQL **não** exposto externamente
- [ ] Senhas fortes (16+ caracteres)
- [ ] Backup automático configurado

### Firewall Recomendado

```bash
# Servidor Zabbix
sudo ufw allow 22/tcp      # SSH
sudo ufw allow 10051/tcp   # Zabbix Server (agents)
sudo ufw allow 8080/tcp    # Zabbix Web
sudo ufw allow 3000/tcp    # Grafana

# Bloquear
sudo ufw deny 5432         # PostgreSQL
sudo ufw deny 9090         # Prometheus (ou apenas localhost)

sudo ufw enable
```

---

## 🚀 Deploy Checklist

### Desenvolvimento (WSL)

- [ ] Execute `./setup.sh` (Modo 3: Desenvolvimento)
- [ ] Container `zabbix-agent` na porta 10060
- [ ] Windows Agent apontando para IP do WSL
- [ ] Validar com `./validate-agent.sh`

### Produção (Ubuntu Server)

- [ ] Servidor com IP fixo
- [ ] Execute `./setup.sh` (Modo 1: Rápido ou 2: Avançado)
- [ ] Container `zabbix-agent` pode usar porta 10050
- [ ] Firewall corporativo liberado
- [ ] Backup automático (cron)
- [ ] Monitoramento do próprio servidor

---

## 📈 Capacidade

**Configuração atual suporta:**
- 2.000-3.000 hosts simultâneos
- ~50.000-150.000 items
- ~5.000-15.000 NVPS

**Para escalar:**
- Zabbix Proxies (múltiplas localidades)
- PostgreSQL HA (replicação)
- Aumentar recursos (CPU/RAM)
- Particionamento de tabelas

---

## 🎓 Lições Aprendidas

### 1. WSL2 Evoluiu
Versões modernas têm networking muito melhorado. Containers conseguem acessar o host Windows nativamente!

### 2. Porta Única para Agents Externos
Manter porta 10050 livre no host facilita muito a adição de agents externos.

### 3. Setup Wizard é Essencial
Detecção automática elimina 99% dos problemas de rede/configuração.

### 4. Validação é Crítica
Script `validate-agent.sh` economiza HORAS de troubleshooting.

### 5. Documentação Clara
README + QUICKSTART + templates = deploy rápido e sem erros.

---

## 📚 Arquivos Importantes

```
zabbix-stack/
├── setup.sh                     # ⭐ Execute PRIMEIRO
├── validate-agent.sh            # ⭐ Para debug de agents
├── .env                         # Gerado pelo setup
├── agent-config-linux.conf      # Template Linux (gerado)
├── agent-config-windows.conf    # Template Windows (gerado)
├── README.md                    # Documentação completa
├── QUICKSTART.md               # Início rápido
└── DEPLOYMENT-NOTES.md         # Este arquivo
```

---

## ✅ Validação Final

### Servidor

```bash
# Health check
./scripts/healthcheck.sh

# Todos containers UP?
docker compose ps

# Portas corretas?
sudo ss -tulpn | grep -E '10051|10060|8080|3000'
```

### Agents

```bash
# Conectividade OK?
./validate-agent.sh

# Zabbix Web: ZBX verde?
# Monitoring → Hosts → Availability

# Dados aparecendo?
# Monitoring → Latest data
```

### Grafana

```bash
# Datasource OK?
# Configuration → Data Sources → Test

# Dashboards mostrando dados?
# Dashboards → Browse
```

---

## 🎯 Próximas Melhorias Sugeridas

1. **Alertmanager** - Notificações avançadas
2. **Traefik** - Reverse proxy com SSL automático
3. **PostgreSQL HA** - Replicação + failover
4. **Zabbix Proxies** - Para sites remotos
5. **ElasticSearch/Loki** - Logs centralizados
6. **Redis Cache** - Performance do Zabbix Web
7. **Backup para S3** - Backup remoto automático

---

**Documentado em:** 13/01/2025  
**Versão:** 1.1  
**Ambiente validado:** WSL2 (Windows 11) + Ubuntu Server