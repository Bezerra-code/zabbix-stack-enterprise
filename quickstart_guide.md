# 🚀 Quick Start - Stack Zabbix Enterprise

## 📦 Instalação em 3 Passos

### 1️⃣ Clone o Projeto

```bash
cd ~
git clone <seu-repo> zabbix-stack
cd zabbix-stack
```

### 2️⃣ Execute o Setup Wizard

```bash
chmod +x setup.sh
./setup.sh
```

**O wizard vai:**
- ✅ Detectar seu ambiente (Linux, WSL, macOS)
- ✅ Descobrir IPs automaticamente
- ✅ Configurar portas e rede
- ✅ Gerar senhas fortes
- ✅ Criar `.env` configurado
- ✅ Gerar templates dos agents
- ✅ Iniciar o stack completo

### 3️⃣ Acessar Serviços

**Zabbix Web:** `http://SEU_IP:8080`
- Usuário: `Admin`
- Senha: `zabbix` ⚠️ **TROCAR IMEDIATAMENTE!**

**Grafana:** `http://SEU_IP:3000`
- Usuário: `admin`
- Senha: (ver em `.env`)

---

## 🖥️ Adicionar Hosts

### Linux

```bash
# 1. Instalar agent
wget https://repo.zabbix.com/zabbix/7.4/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest_7.4+ubuntu22.04_all.deb
sudo dpkg -i zabbix-release_latest_7.4+ubuntu22.04_all.deb
sudo apt update && sudo apt install zabbix-agent2 -y

# 2. Usar template (gerado pelo setup.sh)
sudo cp agent-config-linux.conf /etc/zabbix/zabbix_agent2.conf

# 3. Editar hostname (IMPORTANTE!)
sudo nano /etc/zabbix/zabbix_agent2.conf
# Alterar: Hostname=ALTERE_PARA_NOME_UNICO
# Para: Hostname=servidor-web-01

# 4. Iniciar
sudo systemctl restart zabbix-agent2
sudo systemctl enable zabbix-agent2
sudo ufw allow 10050/tcp

# 5. Testar
zabbix_agent2 -t agent.ping
```

### Windows

```powershell
# 1. Baixar e instalar agent
# https://www.zabbix.com/# 🚀 Quick Start - Stack Zabbix Enterprise

## 📦 Instalação em 5 Minutos

### 1️⃣ Pré-requisitos

```bash
# Ubuntu/Debian
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# Logout e login novamente
```

### 2️⃣ Clone/Download do Projeto

```bash
cd ~
git clone <seu-repo> zabbix-stack
cd zabbix-stack
```

### 3️⃣ Execute o Setup Wizard

```bash
chmod +x setup.sh
./setup.sh
```

O wizard vai:
- ✅ Detectar seu ambiente automaticamente
- ✅ Descobrir IPs disponíveis
- ✅ Gerar senhas fortes
- ✅ Criar arquivo `.env` configurado
- ✅ Criar templates de configuração dos agents
- ✅ Iniciar o stack completo

### 4️⃣ Acessar Serviços

Após o setup, acesse:

**Zabbix Web:** `http://SEU_IP:8080`
- Usuário: `Admin`
- Senha: `zabbix` ⚠️ **ALTERE IMEDIATAMENTE!**

**Grafana:** `http://SEU_IP:3000`
- Usuário: `admin`
- Senha: (verificar em `.env`)

---

## 🖥️ Adicionar Hosts para Monitorar

### Linux

```bash
# No host que será monitorado:
wget https://repo.zabbix.com/zabbix/7.4/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest_7.4+ubuntu22.04_all.deb
sudo dpkg -i zabbix-release_latest_7.4+ubuntu22.04_all.deb
sudo apt update
sudo apt install zabbix-agent2 -y

# Copiar configuração gerada pelo wizard:
sudo cp agent-config-linux.conf /etc/zabbix/zabbix_agent2.conf

# IMPORTANTE: Editar e alterar o Hostname para nome único!
sudo nano /etc/zabbix/zabbix_agent2.conf

# Iniciar
sudo systemctl restart zabbix-agent2
sudo systemctl enable zabbix-agent2
```

### Windows

1. Baixar agent: https://www.zabbix.com/download_agents
2. Instalar o MSI
3. Copiar conteúdo de `agent-config-windows.conf`
4. Colar em `C:\Program Files\Zabbix Agent 2\zabbix_agent2.conf`
5. **IMPORTANTE:** Alterar o Hostname para nome único!
6. Reiniciar serviço "Zabbix Agent 2"

### Adicionar no Zabbix Web

1. Acessar: **Data collection → Hosts → Create host**
2. Configurar:
   - **Host name:** mesmo configurado no agent
   - **Interface (Agent):** `IP_DO_HOST:10050`
   - **Templates:** 
     - Linux: `Linux by Zabbix agent active`
     - Windows: `Windows by Zabbix agent active`
   - **Host groups:** `Linux servers` ou `Windows servers`
3. Clicar em **Add**
4. Aguardar 1-2 minutos
5. Verificar ícone verde (ZBX) na coluna Availability

---

## 🎯 Cenários de Uso

### Cenário 1: Servidor Ubuntu em Rede Corporativa

```bash
./setup.sh

# Escolher:
# 1) Modo Rápido
# Confirmar IP detectado: 192.168.1.100
# Gerar senhas automaticamente: S
# Iniciar containers: S
```

**Resultado:**
- Stack acessível em `http://192.168.1.100:8080`
- Agents externos podem se conectar ao IP `192.168.1.100`

### Cenário 2: Servidor Cloud (AWS/Azure/GCP)

```bash
./setup.sh

# Escolher:
# 1) Modo Rápido
# IP será detectado automaticamente (IP privado ou público)
# Gerar senhas: S
# Iniciar: S
```

**Importante:** Liberar portas no Security Group/Firewall:
- 10051 (Zabbix Server - agents)
- 8080 (Zabbix Web)
- 3000 (Grafana)

### Cenário 3: Múltiplas VLANs

```bash
./setup.sh

# Escolher:
# 2) Modo Avançado
# Escolher IP da VLAN de gerência: 10.10.10.100
# Bind interface: 3) 10.10.10.100 (apenas este IP)
```

### Cenário 4: Desenvolvimento Local (WSL/Docker Desktop)

```bash
./setup.sh

# Escolher:
# 3) Desenvolvimento
# Tudo será configurado para localhost (127.0.0.1)
```

---

## 📊 Configurar Grafana

### 1. Adicionar Zabbix como Datasource

1. Grafana → **Configuration → Data Sources → Add data source**
2. Escolher **Zabbix**
3. Configurar:
   ```
   URL: http://zabbix-web:8080/api_jsonrpc.php
   Username: Admin
   Password: zabbix
   ```
4. **Save & Test**

### 2. Importar Dashboards

Os dashboards já estão em `grafana/dashboards/`:
- `postgres-monitoring.json` - PostgreSQL
- `zabbix.json` - Zabbix Stack
- `docker-containers.json` - Containers
- `nodeexporter.json` - Sistema

**Importar via UI:**
1. **+ → Import**
2. Upload do arquivo JSON
3. Selecionar datasource **Prometheus** ou **Zabbix**
4. **Import**

---

## 🔧 Comandos Úteis

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

# Backup
./scripts/backup.sh

# Health check
./scripts/healthcheck.sh

# Ver uso de recursos
docker stats
```

---

## 🆘 Troubleshooting Rápido

### Agent não conecta

```bash
# No host com agent:
zabbix_agent2 -t agent.ping

# No servidor Zabbix:
docker exec zabbix-server zabbix_get -s IP_DO_HOST -k agent.ping

# Verificar firewall:
sudo ufw allow 10050/tcp  # No host
sudo ufw allow 10051/tcp  # No servidor
```

### Zabbix Web não abre

```bash
# Verificar status
docker compose ps

# Ver logs
docker compose logs zabbix-web

# Reiniciar
docker compose restart zabbix-web zabbix-server
```

### Grafana não mostra dados

1. Verificar datasource: **Configuration → Data Sources**
2. Testar conexão: **Save & Test**
3. Verificar query no dashboard: **Edit → Query Inspector**

---

## 🔐 Segurança

### Trocar Senhas Padrão

**Zabbix:**
1. Login com `Admin` / `zabbix`
2. **Administration → Users → Admin**
3. **Change password**

**Grafana:**
- Senha já definida no `.env` durante setup

### Reconfigurar Stack

```bash
# Se precisar mudar IPs ou configurações:
./setup.sh

# Ou editar manualmente:
nano .env

# Aplicar mudanças:
docker compose up -d --force-recreate
```

---

## 📚 Documentação Completa

Ver `README.md` para:
- Arquitetura detalhada
- Otimizações avançadas
- Backup e restore
- Escalabilidade
- High Availability
- Troubleshooting completo

---

## 🎓 Próximos Passos

1. ✅ Trocar senha padrão do Zabbix
2. ✅ Adicionar primeiro host
3. ✅ Configurar datasource no Grafana
4. ✅ Importar dashboards
5. ✅ Configurar backup automático (cron)
6. ✅ Documentar seus hosts e templates
7. ✅ Configurar alertas (Prometheus ou Zabbix)

---

## 💡 Dicas

- **Backup:** Configure cron para `./scripts/backup.sh` diário
- **Monitoramento:** Use `./scripts/healthcheck.sh` para verificar saúde
- **Logs:** Sempre verifique logs em caso de problemas
- **Senhas:** Guarde o `.env` em local seguro (gerenciador de senhas)
- **Git:** NUNCA commite o `.env` (já está no `.gitignore`)

---

## 🆘 Suporte

- 📖 Documentação: `README.md`
- 🐛 Troubleshooting: Seção no README
- 📝 Logs: `docker compose logs -f`
- 🔍 Health Check: `./scripts/healthcheck.sh`
