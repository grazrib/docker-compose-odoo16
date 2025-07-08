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

# Configurazioni predefinite (MODIFICA QUESTE!)
ODOO_MASTER_PASSWORD="MySecurePassword123!"
DB_USER="odoo"
DB_PASSWORD="SecureDbPassword456!"
PGADMIN_EMAIL="admin@yourdomain.com"
PGADMIN_PASSWORD="SecurePgPassword789!"
COMPANY_NAME="La Mia Azienda"
SMTP_EMAIL="noreply@yourdomain.com"
SMTP_SERVER="localhost"
SMTP_PORT="587"
PROXY_MODE_VALUE="True"  # True per OpenLiteSpeed
DEV_MODE_VALUE=""        # Vuoto per production

# Performance (modifica in base al tuo server)
CPU_CORES=2
RAM_GB=8
TOTAL_INSTANCES=1
CONCURRENT_USERS=10

# Calcola configurazioni
WORKERS_PER_INSTANCE=$((($CPU_CORES * 2) / $TOTAL_INSTANCES))
if [ $WORKERS_PER_INSTANCE -lt 1 ]; then
    WORKERS_PER_INSTANCE=1
fi

RAM_MB=$(($RAM_GB * 1024))
RAM_PER_INSTANCE=$(($RAM_MB / $TOTAL_INSTANCES))
LIMIT_MEMORY_SOFT=$((($RAM_PER_INSTANCE * 1024 * 1024 * 60) / 100))
LIMIT_MEMORY_HARD=$((($RAM_PER_INSTANCE * 1024 * 1024 * 80) / 100))
DB_MAXCONN=$(($WORKERS_PER_INSTANCE * 2 + 10))

echo "=== INSTALLAZIONE RAPIDA ODOO 16 ==="
echo "🔐 ATTENZIONE: Usando credenziali predefinite!"
echo "📝 Modifica lo script per cambiare le password!"
echo

echo "⚙️  Clonazione repository..."
git clone --depth=1 https://github.com/grazrib/docker-compose-odoo16.git $DESTINATION
rm -rf $DESTINATION/.git

echo "📁 Creazione directory..."
mkdir -p $DESTINATION/postgresql
mkdir -p $DESTINATION/addons
mkdir -p $DESTINATION/etc
mkdir -p $DESTINATION/pgadmin-data

echo "🔧 Configurazione file..."
# Aggiorna docker-compose.yml
sed -i "s/POSTGRES_PASSWORD=odoo16@2025/POSTGRES_PASSWORD=$DB_PASSWORD/g" $DESTINATION/docker-compose.yml
sed -i "s/PASSWORD=odoo16@2025/PASSWORD=$DB_PASSWORD/g" $DESTINATION/docker-compose.yml
sed -i "s/POSTGRES_USER=odoo/POSTGRES_USER=$DB_USER/g" $DESTINATION/docker-compose.yml
sed -i "s/USER=odoo/USER=$DB_USER/g" $DESTINATION/docker-compose.yml
sed -i "s/email@to_be_modified/$PGADMIN_EMAIL/g" $DESTINATION/docker-compose.yml
sed -i "s/PGADMIN_DEFAULT_PASSWORD: 'to_be_modified'/PGADMIN_DEFAULT_PASSWORD: '$PGADMIN_PASSWORD'/g" $DESTINATION/docker-compose.yml

# Aggiorna entrypoint.sh
sed -i "s/POSTGRES_PASSWORD:='odoo16@2025'}/POSTGRES_PASSWORD:='$DB_PASSWORD'}/g" $DESTINATION/entrypoint.sh
sed -i "s/POSTGRES_USER:='odoo'}/POSTGRES_USER:='$DB_USER'}/g" $DESTINATION/entrypoint.sh

# Crea odoo.conf
cat > $DESTINATION/etc/odoo.conf << EOF
[options]
# ===================
# | Configurazione Odoo 16 |
# ===================

admin_passwd = $ODOO_MASTER_PASSWORD
addons_path = /mnt/extra-addons
data_dir = /etc/odoo

# ==============================
# | HTTP Service |
# ==============================
http_port = 8069
gevent_port = 8072
proxy_mode = $PROXY_MODE_VALUE

# ===============================
# | Database |
# ===============================
db_host = db
db_port = 5432
db_user = $DB_USER
db_password = $DB_PASSWORD
db_maxconn = $DB_MAXCONN
db_template = template0

# ============================
# | SMTP |
# ============================
email_from = $SMTP_EMAIL
smtp_server = $SMTP_SERVER
smtp_port = $SMTP_PORT
smtp_ssl = False

# =========================
# | Logging |
# =========================
logfile = /etc/odoo/odoo-server.log
log_level = info
log_db_level = warning

# ============================
# | Security |
# ============================
list_db = True
# dbfilter = ^%h$|^%d$

# ===========================
# | Performance |
# ===========================
workers = $WORKERS_PER_INSTANCE
limit_memory_soft = $LIMIT_MEMORY_SOFT
limit_memory_hard = $LIMIT_MEMORY_HARD
limit_time_cpu = 60
limit_time_real = 120
limit_request = 8192
max_cron_threads = 2

# ========================
# | Extra |
# ========================
unaccent = True
without_demo = all
EOF

if [ ! -z "$DEV_MODE_VALUE" ]; then
    echo "dev_mode = $DEV_MODE_VALUE" >> $DESTINATION/etc/odoo.conf
fi

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

# set executable permission for entrypoint.sh (fix Docker permission denied)
sudo chmod 755 $DESTINATION/entrypoint.sh

echo "⚙️  Configurazione sistema..."
if grep -qF "fs.inotify.max_user_watches" /etc/sysctl.conf; then 
    echo $(grep -F "fs.inotify.max_user_watches" /etc/sysctl.conf)
else 
    echo "fs.inotify.max_user_watches = 524288" | sudo tee -a /etc/sysctl.conf
fi
sudo sysctl -p

sed -i 's/10016/'$PORT'/g' $DESTINATION/docker-compose.yml
sed -i 's/20016/'$CHAT'/g' $DESTINATION/docker-compose.yml

echo
echo "✅ CONFIGURAZIONE COMPLETATA!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📁 Installazione: $DESTINATION/"
echo "🔧 MODIFICA LE CREDENZIALI in:"
echo "   └─ $DESTINATION/etc/odoo.conf"
echo "   └─ $DESTINATION/docker-compose.yml"
echo "   └─ $DESTINATION/entrypoint.sh"
echo
echo "🔐 Password correnti (DA CAMBIARE!):"
echo "   └─ Odoo Master: $ODOO_MASTER_PASSWORD"
echo "   └─ Database: $DB_PASSWORD"
echo "   └─ pgAdmin: $PGADMIN_PASSWORD"
echo
echo "🚀 Per avviare dopo le modifiche:"
echo "   cd $DESTINATION"
echo "   docker-compose up -d"
echo
echo "🌐 URLs dopo l'avvio:"
echo "   └─ Odoo: http://localhost:$PORT"
echo "   └─ pgAdmin: http://localhost:5050"
echo "   └─ Live Chat: http://localhost:$CHAT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
