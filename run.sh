#!/bin/bash
DESTINATION=$1
PORT=$2
CHAT=$3

# Verifica parametri
if [ -z "$DESTINATION" ] || [ -z "$PORT" ] || [ -z "$CHAT" ]; then
    echo "Uso: $0 <destination_folder> <odoo_port> <chat_port>"
    echo "Esempio: $0 odoo16-instance 10016 20016"
    exit 1
fi

echo "=== CONFIGURAZIONE ODOO 16 INSTANCE ==="
echo "Cartella: $DESTINATION"
echo "Porta Odoo: $PORT"
echo "Porta Chat: $CHAT"
echo

# Richiedi credenziali Odoo
echo "--- CREDENZIALI ODOO ---"
read -p "Master Password Odoo [obbligatorio]: " ODOO_MASTER_PASSWORD
while [ -z "$ODOO_MASTER_PASSWORD" ]; do
    echo "⚠️  La Master Password è obbligatoria!"
    read -p "Master Password Odoo: " ODOO_MASTER_PASSWORD
done

# Richiedi credenziali Database
echo
echo "--- CREDENZIALI DATABASE ---"
read -p "Database User [odoo]: " DB_USER
DB_USER=${DB_USER:-odoo}
read -s -p "Database Password [obbligatoria]: " DB_PASSWORD
echo
while [ -z "$DB_PASSWORD" ]; do
    echo "⚠️  La password del database è obbligatoria!"
    read -s -p "Database Password: " DB_PASSWORD
    echo
done

# Richiedi credenziali pgAdmin
echo
echo "--- CREDENZIALI PGADMIN ---"
read -p "pgAdmin Email [admin@localhost]: " PGADMIN_EMAIL
PGADMIN_EMAIL=${PGADMIN_EMAIL:-admin@localhost}
read -s -p "pgAdmin Password [obbligatoria]: " PGADMIN_PASSWORD
echo
while [ -z "$PGADMIN_PASSWORD" ]; do
    echo "⚠️  La password di pgAdmin è obbligatoria!"
    read -s -p "pgAdmin Password: " PGADMIN_PASSWORD
    echo
done

# Configurazioni aggiuntive Odoo
echo
echo "--- CONFIGURAZIONI ODOO ---"
read -p "Nome azienda [La Mia Azienda]: " COMPANY_NAME
COMPANY_NAME=${COMPANY_NAME:-"La Mia Azienda"}

read -p "Email mittente SMTP [noreply@localhost]: " SMTP_EMAIL
SMTP_EMAIL=${SMTP_EMAIL:-noreply@localhost}

read -p "Server SMTP [localhost]: " SMTP_SERVER
SMTP_SERVER=${SMTP_SERVER:-localhost}

read -p "Porta SMTP [587]: " SMTP_PORT
SMTP_PORT=${SMTP_PORT:-587}

# Proxy mode per OpenLiteSpeed
read -p "Abilitare proxy mode (per OpenLiteSpeed/Nginx)? [y/N]: " PROXY_MODE
if [[ $PROXY_MODE =~ ^[Yy]$ ]]; then
    PROXY_MODE_VALUE="True"
else
    PROXY_MODE_VALUE="False"
fi

read -p "Abilitare modalità sviluppo? [y/N]: " DEV_MODE
if [[ $DEV_MODE =~ ^[Yy]$ ]]; then
    DEV_MODE_VALUE="reload,qweb,werkzeug,xml"
else
    DEV_MODE_VALUE=""
fi

# Configurazione performance basata su risorse server
echo
echo "--- CONFIGURAZIONE PERFORMANCE ---"
echo "🖥️  Configuriamo le risorse per il tuo server"

read -p "CPU cores disponibili [2]: " CPU_CORES
CPU_CORES=${CPU_CORES:-2}

read -p "RAM disponibile GB [8]: " RAM_GB
RAM_GB=${RAM_GB:-8}

read -p "Spazio disco GB [100]: " DISK_GB
DISK_GB=${DISK_GB:-100}

read -p "Quante istanze Odoo prevedi su questo server? [1]: " TOTAL_INSTANCES
TOTAL_INSTANCES=${TOTAL_INSTANCES:-1}

read -p "Utenti concorrenti stimati per questa istanza [10]: " CONCURRENT_USERS
CONCURRENT_USERS=${CONCURRENT_USERS:-10}

# Calcola configurazioni ottimali
WORKERS_PER_INSTANCE=$((($CPU_CORES * 2) / $TOTAL_INSTANCES))
if [ $WORKERS_PER_INSTANCE -lt 1 ]; then
    WORKERS_PER_INSTANCE=1
fi

# RAM per worker (in MB)
RAM_MB=$(($RAM_GB * 1024))
RAM_PER_INSTANCE=$(($RAM_MB / $TOTAL_INSTANCES))
LIMIT_MEMORY_SOFT=$((($RAM_PER_INSTANCE * 1024 * 1024 * 60) / 100))  # 60% in bytes
LIMIT_MEMORY_HARD=$((($RAM_PER_INSTANCE * 1024 * 1024 * 80) / 100))   # 80% in bytes

# Calcola DB connections
DB_MAXCONN=$(($WORKERS_PER_INSTANCE * 2 + 10))

echo "📊 Configurazione calcolata:"
echo "   Workers: $WORKERS_PER_INSTANCE"
echo "   Memory Soft: $((LIMIT_MEMORY_SOFT / 1024 / 1024))MB"
echo "   Memory Hard: $((LIMIT_MEMORY_HARD / 1024 / 1024))MB"
echo "   DB Connections: $DB_MAXCONN"

echo
echo "⚙️  Clonazione repository..."
# clone Odoo directory
git clone --depth=1 https://github.com/grazrib/docker-compose-odoo16.git $DESTINATION
rm -rf $DESTINATION/.git

echo "📁 Creazione directory..."
# create directories
mkdir -p $DESTINATION/postgresql
mkdir -p $DESTINATION/addons
mkdir -p $DESTINATION/etc
mkdir -p $DESTINATION/pgadmin-data

echo "🔧 Configurazione file..."
# Aggiorna docker-compose.yml con le credenziali
sed -i "s/POSTGRES_PASSWORD=odoo16@2025/POSTGRES_PASSWORD=$DB_PASSWORD/g" $DESTINATION/docker-compose.yml
sed -i "s/PASSWORD=odoo16@2025/PASSWORD=$DB_PASSWORD/g" $DESTINATION/docker-compose.yml
sed -i "s/POSTGRES_USER=odoo/POSTGRES_USER=$DB_USER/g" $DESTINATION/docker-compose.yml
sed -i "s/USER=odoo/USER=$DB_USER/g" $DESTINATION/docker-compose.yml
sed -i "s/email@to_be_modified/$PGADMIN_EMAIL/g" $DESTINATION/docker-compose.yml
sed -i "s/PGADMIN_DEFAULT_PASSWORD: 'to_be_modified'/PGADMIN_DEFAULT_PASSWORD: '$PGADMIN_PASSWORD'/g" $DESTINATION/docker-compose.yml

# Aggiorna entrypoint.sh con le credenziali
sed -i "s/POSTGRES_PASSWORD:='odoo16@2025'}/POSTGRES_PASSWORD:='$DB_PASSWORD'}/g" $DESTINATION/entrypoint.sh
sed -i "s/POSTGRES_USER:='odoo'}/POSTGRES_USER:='$DB_USER'}/g" $DESTINATION/entrypoint.sh

# Crea odoo.conf personalizzato
cat > $DESTINATION/etc/odoo.conf << EOF
[options]
# ===================
# | Configurazione base Odoo 16 |
# ===================

# Password master per gestione database
admin_passwd = $ODOO_MASTER_PASSWORD

# Percorsi addons
addons_path = /mnt/extra-addons

# Directory dati
data_dir = /etc/odoo

# ==============================
# | Configurazione HTTP |
# ==============================
http_port = 8069
longpolling_port = 8072
proxy_mode = $PROXY_MODE_VALUE

# ===============================
# | Configurazione Database |
# ===============================
db_host = db
db_port = 5432
db_user = $DB_USER
db_password = $DB_PASSWORD
db_maxconn = $DB_MAXCONN
db_template = template0

# ============================
# | Configurazione SMTP |
# ============================
email_from = $SMTP_EMAIL
smtp_server = $SMTP_SERVER
smtp_port = $SMTP_PORT
smtp_ssl = False
smtp_user = 
smtp_password = 

# =========================
# | Configurazione Log |
# =========================
logfile = /etc/odoo/odoo-server.log
log_level = info
log_db_level = warning

# ============================
# | Sicurezza |
# ============================
list_db = True
dbfilter = ^%h$|^%d$

# ====================
# | Opzioni avanzate |
# ====================
EOF

# Aggiungi modalità sviluppo se richiesta
if [ ! -z "$DEV_MODE_VALUE" ]; then
    echo "dev_mode = $DEV_MODE_VALUE" >> $DESTINATION/etc/odoo.conf
fi

# Continua con le configurazioni performance
cat >> $DESTINATION/etc/odoo.conf << EOF

# ===========================
# | Performance |
# ===========================
# Configurazione ottimizzata per:
# - CPU: $CPU_CORES cores (condivisi tra $TOTAL_INSTANCES istanze)
# - RAM: $RAM_GB GB (${RAM_PER_INSTANCE}MB per questa istanza)
# - Utenti concorrenti stimati: $CONCURRENT_USERS
workers = $WORKERS_PER_INSTANCE
limit_memory_soft = $LIMIT_MEMORY_SOFT
limit_memory_hard = $LIMIT_MEMORY_HARD
limit_time_cpu = 60
limit_time_real = 120
limit_request = 8192
max_cron_threads = 2

# Per production con più utenti, decommenta e modifica:
# workers = $((WORKERS_PER_INSTANCE + 2))
# limit_memory_soft = $((LIMIT_MEMORY_SOFT - (LIMIT_MEMORY_SOFT * 20 / 100)))
# limit_memory_hard = $((LIMIT_MEMORY_HARD - (LIMIT_MEMORY_HARD * 20 / 100)))
# limit_time_cpu = 120
# limit_time_real = 240
# max_cron_threads = 4

# ========================
# | Configurazioni extra |
# ========================
unaccent = True
without_demo = all
EOF

echo "🔐 Impostazione permessi..."
# set correct permissions for docker users
sudo chown -R 101:101 $DESTINATION/addons
sudo chown -R 101:101 $DESTINATION/etc
sudo chown -R 999:999 $DESTINATION/postgresql
sudo chown -R 5050:5050 $DESTINATION/pgadmin-data

sudo chmod -R 755 $DESTINATION/addons
sudo chmod -R 755 $DESTINATION/etc
sudo chmod -R 755 $DESTINATION/postgresql
sudo chmod -R 755 $DESTINATION/pgadmin-data

echo "⚙️  Configurazione sistema..."
# config inotify for multiple Odoo instances
if grep -qF "fs.inotify.max_user_watches" /etc/sysctl.conf; then 
    echo $(grep -F "fs.inotify.max_user_watches" /etc/sysctl.conf)
else 
    echo "fs.inotify.max_user_watches = 524288" | sudo tee -a /etc/sysctl.conf
fi
sudo sysctl -p

# configure ports in docker-compose.yml
sed -i 's/10016/'$PORT'/g' $DESTINATION/docker-compose.yml
sed -i 's/20016/'$CHAT'/g' $DESTINATION/docker-compose.yml

echo "🚀 Avvio container..."
# run Odoo
docker-compose -f $DESTINATION/docker-compose.yml up -d

echo
echo "✅ INSTALLAZIONE COMPLETATA!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🌐 Odoo 16: http://localhost:$PORT"
echo "🔐 Master Password: $ODOO_MASTER_PASSWORD"
echo "💬 Live Chat: http://localhost:$CHAT"
echo "🗄️  pgAdmin: http://localhost:5050"
echo "   └─ Email: $PGADMIN_EMAIL"
echo "   └─ Password: [configurata]"
echo "📊 Database: $DB_USER@localhost:5432"
echo "⚙️  Workers: $WORKERS_PER_INSTANCE | Proxy Mode: $PROXY_MODE_VALUE"
echo "📖 Leggi README.md per configurazione OpenLiteSpeed"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
