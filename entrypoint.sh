#!/bin/bash
set -e

# Imposta le variabili del database PostgreSQL in base all'ambiente
# e le passa come argomenti al processo odoo se non presenti nel file di configurazione
: ${HOST:=${DB_PORT_5432_TCP_ADDR:='db'}}
: ${PORT:=${DB_PORT_5432_TCP_PORT:=5432}}
: ${USER:=${DB_ENV_POSTGRES_USER:=${POSTGRES_USER:='odoo'}}}
: ${PASSWORD:=${DB_ENV_POSTGRES_PASSWORD:=${POSTGRES_PASSWORD:='odoo16@2025'}}}

# File di configurazione di Odoo
ODOO_RC=${ODOO_RC:=/etc/odoo/odoo.conf}

# Installa pacchetti Python se il file requirements.txt esiste
if [ -f "/etc/odoo/requirements.txt" ]; then
    echo "Installazione pacchetti Python da requirements.txt..."
    pip3 install --upgrade pip
    pip3 install -r /etc/odoo/requirements.txt
fi

# Array per gli argomenti del database
DB_ARGS=()

# Funzione per verificare la configurazione
function check_config() {
    param="$1"
    value="$2"
    
    # Se il parametro esiste nel file di configurazione, usa quel valore
    if [ -f "$ODOO_RC" ] && grep -q -E "^\s*\b${param}\b\s*=" "$ODOO_RC" ; then       
        value=$(grep -E "^\s*\b${param}\b\s*=" "$ODOO_RC" | cut -d "=" -f2- | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sed 's/["\n\r]//g')
    fi
    
    # Aggiungi agli argomenti del database
    DB_ARGS+=("--${param}")
    DB_ARGS+=("${value}")
}

# Configura i parametri del database
check_config "db_host" "$HOST"
check_config "db_port" "$PORT"
check_config "db_user" "$USER"
check_config "db_password" "$PASSWORD"

# Gestione dei comandi
case "$1" in
    -- | odoo)
        shift
        if [[ "$1" == "scaffold" ]] ; then
            # Per il comando scaffold, esegui direttamente
            exec odoo "$@"
        else
            # Aspetta che PostgreSQL sia pronto
            echo "Attendo che PostgreSQL sia disponibile..."
            wait-for-psql.py ${DB_ARGS[@]} --timeout=30
            echo "PostgreSQL è disponibile, avvio Odoo..."
            exec odoo "$@" "${DB_ARGS[@]}"
        fi
        ;;
    -*)
        # Per opzioni che iniziano con -, aspetta PostgreSQL
        echo "Attendo che PostgreSQL sia disponibile..."
        wait-for-psql.py ${DB_ARGS[@]} --timeout=30
        echo "PostgreSQL è disponibile, avvio Odoo con opzioni..."
        exec odoo "$@" "${DB_ARGS[@]}"
        ;;
    *)
        # Per altri comandi, esegui direttamente
        exec "$@"
esac
