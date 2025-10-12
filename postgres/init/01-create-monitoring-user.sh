#!/bin/bash
set -e

echo "🔧 Criando usuário monitoring para Postgres Exporter..."

# Verificar se variáveis existem
if [ -z "$MONITORING_USER" ] || [ -z "$MONITORING_PASSWORD" ]; then
    echo "❌ ERRO: Variáveis MONITORING_USER ou MONITORING_PASSWORD não definidas!"
    exit 1
fi

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Criar usuário monitoring
    DO \$\$
    BEGIN
        IF NOT EXISTS (SELECT FROM pg_user WHERE usename = '$MONITORING_USER') THEN
            CREATE USER $MONITORING_USER WITH PASSWORD '$MONITORING_PASSWORD';
        END IF;
    END
    \$\$;

    -- Dar permissões
    GRANT pg_monitor TO $MONITORING_USER;
    GRANT CONNECT ON DATABASE $POSTGRES_DB TO $MONITORING_USER;
    GRANT USAGE ON SCHEMA public TO $MONITORING_USER;
    GRANT SELECT ON ALL TABLES IN SCHEMA public TO $MONITORING_USER;
    
    -- Criar banco grafana se não existir
    SELECT 'CREATE DATABASE grafana' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'grafana')\gexec
    GRANT CONNECT ON DATABASE grafana TO $MONITORING_USER;

EOSQL

echo "✅ Usuário $MONITORING_USER criado com sucesso!"