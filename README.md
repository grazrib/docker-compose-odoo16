# Docker Compose Odoo 16 

**Installazione rapida di Odoo 16 con un solo comando.**  
Supporta istanze multiple su un singolo server con fix SSL/TLS testati.

[![Docker](https://img.shields.io/badge/Docker-✓-blue)](https://www.docker.com/)
[![Odoo 16](https://img.shields.io/badge/Odoo-16.0-purple)](https://www.odoo.com/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-blue)](https://postgresql.org/)

## 🚀 Installazione Rapida

Installa [Docker](https://docs.docker.com/get-docker/) e [Docker Compose](https://docs.docker.com/compose/install/), poi esegui:

```bash
curl -s https://raw.githubusercontent.com/grazrib/docker-compose-odoo16/master/run.sh | sudo bash -s odoo-one 10016 20016
```

**Prima istanza** → `http://localhost:10016` (Password: `to_be_modified`)

Per una seconda istanza:
```bash
curl -s https://raw.githubusercontent.com/grazrib/docker-compose-odoo16/master/run.sh | sudo bash -s odoo-two 11016 21016
```

**Seconda istanza** → `http://localhost:11016`

### Parametri
- **odoo-one**: Nome directory installazione
- **10016**: Porta Odoo
- **20016**: Porta live chat

## 📋 Cosa include

- ✅ **Odoo 16** con fix SSL/TLS funzionanti
- ✅ **PostgreSQL 15** ottimizzato 
- ✅ **PgAdmin 4** per gestione database
- ✅ **Volumi Docker** per persistenza dati
- ✅ **Health checks** automatici
- ✅ **Support OCA addons** ready

## 🔧 Utilizzo Manuale

```bash
# Clona repository
git clone https://github.com/grazrib/docker-compose-odoo16.git
cd docker-compose-odoo16

# Avvia servizi
docker-compose up -d

# Accedi a Odoo
# http://localhost:10016
```

## 🌐 Accessi

| Servizio | URL | Credenziali |
|----------|-----|-------------|
| **Odoo** | http://localhost:10016 | Master: `to_be_modified` |
| **PgAdmin** | http://localhost:5050 | Email: `admin@example.com`<br>Pass: `admin123` |
| **Live Chat** | Porta 20016 | Configurato automaticamente |

## ⚙️ Configurazione OpenLiteSpeed

### Virtual Host Configuration

Crea un Virtual Host con questi Context:

**Context 1 - Main App:**
```
Type: Proxy
URI: /
Address: 127.0.0.1:10016
Extra Headers:
X-Real-IP $remote_addr
X-Forwarded-For $proxy_add_x_forwarded_for
X-Forwarded-Proto $scheme
X-Forwarded-Host $host
```

**Context 2 - Live Chat:**
```
Type: Proxy  
URI: /longpolling/
Address: 127.0.0.1:20016
Extra Headers:
X-Real-IP $remote_addr
X-Forwarded-For $proxy_add_x_forwarded_for
X-Forwarded-Proto $scheme
X-Forwarded-Host $host
```

### Rewrite Rules
```apache
RewriteEngine On

# Main Odoo traffic
RewriteCond %{REQUEST_URI} !^/longpolling/
RewriteRule ^(.*)$ http://127.0.0.1:10016$1 [P,L]

# Longpolling traffic
RewriteRule ^/longpolling/(.*)$ http://127.0.0.1:20016/longpolling/$1 [P,L]
```

## 🛠️ Gestione Container

```bash
# Visualizza stato
docker-compose ps

# Logs in tempo reale  
docker-compose logs -f odoo16

# Riavvia servizi
docker-compose restart

# Ferma tutto
docker-compose down

# Rebuild completo
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

## 📁 Struttura Directory

```
odoo-one/
├── docker-compose.yml    # Configurazione servizi
├── Dockerfile           # Build Odoo personalizzato  
├── entrypoint.sh        # Script avvio Odoo
├── addons/             # Custom addons
├── etc/                # Configurazione Odoo
│   ├── odoo.conf       # File configurazione principale
│   └── requirements.txt # Dipendenze Python
└── clone-oca.sh        # Script per addons OCA
```

## 🔨 Addons Personalizzati

Posiziona i tuoi addons nella cartella `addons/`:

```bash
# Aggiungi addon personalizzato
cp -r my_custom_addon ./addons/

# Riavvia Odoo per caricare nuovi addons
docker-compose restart odoo16
```

### Addons OCA
```bash
# Scarica tutti gli addons OCA
./clone-oca.sh

# Riavvia per applicare
docker-compose restart odoo16
```

## 🐛 Risoluzione Problemi

### Errore SSL/TLS
```bash
# Se vedi errori X509_V_FLAG_NOTIFY_POLICY
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### Problemi Database
```bash
# Reset completo database
docker-compose down -v
docker-compose up -d

# Backup database
docker-compose exec db pg_dump -U odoo postgres > backup.sql

# Restore database  
docker-compose exec -T db psql -U odoo postgres < backup.sql
```

### Permessi File
```bash
# Ripristina permessi corretti
sudo chmod -R 755 addons etc
sudo chmod +x entrypoint.sh
```

### Performance
```bash
# Controlla risorse
docker stats

# Logs errori
docker-compose logs --tail=50 odoo16
```

## 🔧 Configurazione Avanzata

### File `etc/odoo.conf` ottimale

```ini
[options]
# CONFIGURAZIONE BASE
addons_path = /mnt/extra-addons
data_dir = /etc/odoo
admin_passwd = to_be_modified

# DATABASE
db_host = db
db_port = 5432
db_user = odoo
db_password = odoo16@2025
db_maxconn = 64

# SERVER HTTP
http_port = 8069
longpolling_port = 8072
http_interface = 0.0.0.0

# PERFORMANCE
workers = 0  # Sviluppo: 0, Produzione: 2*CPU+1
limit_memory_soft = 2147483648  # 2GB
limit_memory_hard = 2684354560  # 2.5GB
limit_time_cpu = 60
limit_time_real = 120
max_cron_threads = 2

# LOGGING
logfile = /etc/odoo/odoo-server.log
log_level = info

# SICUREZZA
list_db = True  # Produzione: False
# dbfilter = ^%h$  # Filtra DB per dominio

# SVILUPPO (decommenta per debug)
# dev_mode = reload,qweb
# log_level = debug
```

### Configurazioni per ambiente

**Sviluppo:**
```bash
# Modifica etc/odoo.conf
workers = 0
dev_mode = reload,qweb
log_level = debug
limit_time_real = 300
```

**Produzione:**
```bash
# Modifica etc/odoo.conf  
workers = 8
proxy_mode = True
log_level = warn
list_db = False
admin_passwd = STRONG_PASSWORD_HERE
```

### Environment personalizzato:
```yaml
# In docker-compose.yml
environment:
  - HOST=db
  - USER=odoo  
  - PASSWORD=custom_password
  - PGDATA=/var/lib/postgresql/data/pgdata
```

## 🎯 Comandi Utili

### 🐘 Gestione PostgreSQL

```bash
# Accesso database
docker-compose exec db psql -U odoo -d postgres

# Backup database
docker-compose exec db pg_dump -U odoo -d nome_database > backup_$(date +%Y%m%d).sql

# Restore database
docker-compose exec -T db psql -U odoo -d nome_database < backup.sql

# Lista database
docker-compose exec db psql -U odoo -c "\l"

# Dimensione database
docker-compose exec db psql -U odoo -c "SELECT pg_database.datname, pg_size_pretty(pg_database_size(pg_database.datname)) AS size FROM pg_database;"

# Connessioni attive
docker-compose exec db psql -U odoo -c "SELECT count(*) FROM pg_stat_activity;"

# Kill connessioni database
docker-compose exec db psql -U odoo -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = 'nome_database';"

# Vacuum database
docker-compose exec db psql -U odoo -d nome_database -c "VACUUM ANALYZE;"

# Reindex database
docker-compose exec db psql -U odoo -d nome_database -c "REINDEX DATABASE nome_database;"
```

### 🔧 Gestione Odoo

```bash
# Shell Odoo interattiva
docker-compose exec odoo16 odoo shell -d nome_database

# Aggiorna modulo specifico
docker-compose exec odoo16 odoo -d nome_database -u nome_modulo --stop-after-init

# Installa modulo
docker-compose exec odoo16 odoo -d nome_database -i nome_modulo --stop-after-init

# Lista moduli installati
docker-compose exec odoo16 odoo shell -d nome_database --no-http -c "
env['ir.module.module'].search([('state','=','installed')]).mapped('name')
"

# Creazione database da CLI
docker-compose exec odoo16 odoo -d nuovo_database -i base --stop-after-init

# Backup filestore
docker-compose exec odoo16 tar -czf /tmp/filestore_backup.tar.gz -C /etc/odoo filestore/

# Import/Export dati
docker-compose exec odoo16 odoo -d nome_database --data-dir=/etc/odoo

# Test moduli
docker-compose exec odoo16 odoo -d nome_database --test-enable --stop-after-init

# Rigenerazione assets
docker-compose exec odoo16 odoo -d nome_database -u web --stop-after-init

# Pulizia cache
docker-compose exec odoo16 find /tmp -name "oe-sessions-*" -delete
```

### 📊 PgAdmin Gestione

**Accesso:** http://localhost:5050  
**Email:** admin@example.com  
**Password:** admin123

**Connessione server PostgreSQL in PgAdmin:**
```
Host: db
Port: 5432
Username: odoo
Password: odoo16@2025
Database: postgres
```

**Query utili in PgAdmin:**
```sql
-- Database size
SELECT 
    datname AS database_name,
    pg_size_pretty(pg_database_size(datname)) AS size
FROM pg_database
WHERE datistemplate = false;

-- Tabelle più grandi
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size,
    pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) AS table_size
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC 
LIMIT 10;

-- Connessioni attive
SELECT 
    datname,
    count(*) as connections,
    usename
FROM pg_stat_activity 
GROUP BY datname, usename;

-- Performance query lente
SELECT 
    query,
    mean_time,
    calls
FROM pg_stat_statements 
ORDER BY mean_time DESC 
LIMIT 10;
```

### 🔍 Debugging e Monitoraggio

```bash
# Log in tempo reale
docker-compose logs -f odoo16

# Log PostgreSQL  
docker-compose logs -f db

# Statistiche container
docker stats odoo-one-odoo16-1

# Utilizzo disco
docker system df

# Memoria Odoo
docker-compose exec odoo16 cat /proc/meminfo

# Processi Odoo
docker-compose exec odoo16 ps aux

# Port binding
docker-compose port odoo16 8069

# Health check manuale
curl -I http://localhost:10016

# Test database connection
docker-compose exec odoo16 python3 -c "
import psycopg2
conn = psycopg2.connect(
    host='db',
    database='postgres', 
    user='odoo',
    password='odoo16@2025'
)
print('DB Connection OK')
conn.close()
"

# Memory usage per processo
docker-compose exec odoo16 cat /proc/1/status | grep VmRSS

# Network info
docker network inspect odoo-one_default
```

### ⚡ Performance Tuning

```bash
# PostgreSQL tuning
docker-compose exec db psql -U odoo -c "
ALTER SYSTEM SET shared_buffers = '256MB';
ALTER SYSTEM SET effective_cache_size = '1GB';  
ALTER SYSTEM SET maintenance_work_mem = '64MB';
ALTER SYSTEM SET checkpoint_completion_target = 0.9;
ALTER SYSTEM SET wal_buffers = '16MB';
SELECT pg_reload_conf();
"

# Odoo cache clear
docker-compose exec odoo16 find /tmp -name "*.pyc" -delete

# Restart per applicare modifiche
docker-compose restart

# Monitor performance
docker-compose exec db psql -U odoo -c "
SELECT 
    datname,
    numbackends,
    xact_commit,
    xact_rollback,
    blks_read,
    blks_hit,
    tup_returned,
    tup_fetched
FROM pg_stat_database 
WHERE datname NOT IN ('template0','template1');
"
```

### 🛠️ Manutenzione

```bash
# Pulizia volumi Docker
docker volume prune

# Pulizia immagini inutilizzate
docker image prune

# Backup completo
mkdir backup_$(date +%Y%m%d)
docker-compose exec db pg_dumpall -U odoo > backup_$(date +%Y%m%d)/db_full.sql
docker-compose exec odoo16 tar -czf backup_$(date +%Y%m%d)/filestore.tar.gz -C /etc/odoo filestore/
cp -r etc/ backup_$(date +%Y%m%d)/config/

# Restore completo
docker-compose down
docker volume rm odoo-one_db_data odoo-one_odoo_data
docker-compose up -d db
sleep 30
docker-compose exec -T db psql -U odoo < backup_20241201/db_full.sql
docker-compose up -d

# Aggiornamento Odoo
docker-compose pull
docker-compose up -d --force-recreate

# Reset password admin
docker-compose exec odoo16 odoo shell -d nome_database --no-http -c "
env['res.users'].browse(1).write({'password': 'nuova_password'})
env.cr.commit()
"
```

## 📊 Monitoraggio

```bash
# Health check manuale
curl -I http://localhost:10016

# Database connection test
docker-compose exec db psql -U odoo -c "SELECT version();"

# Odoo modules list
docker-compose exec odoo16 odoo shell -d your_db --no-http

# Performance monitoring
docker stats --no-stream
docker-compose logs --tail=100 odoo16 | grep ERROR
```

## 🚨 Troubleshooting Avanzato

### Problemi SSL/TLS
```bash
# Verifica versioni critiche
docker-compose exec odoo16 python3 -c "
import cryptography, OpenSSL
print(f'cryptography: {cryptography.__version__}')  
print(f'pyOpenSSL: {OpenSSL.__version__}')
"

# Fix forzato SSL
docker-compose exec odoo16 pip install cryptography==3.4.8 pyOpenSSL==19.0.0
docker-compose restart odoo16
```

### Problemi Performance
```bash
# CPU usage
docker stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"

# Slow queries PostgreSQL
docker-compose exec db psql -U odoo -c "
SELECT query, mean_time, calls 
FROM pg_stat_statements 
ORDER BY mean_time DESC LIMIT 5;
"

# Odoo workers overloaded
docker-compose exec odoo16 ps aux | grep odoo
```

### Database Issues
```bash
# Check locks
docker-compose exec db psql -U odoo -c "
SELECT blocked_locks.pid AS blocked_pid,
       blocking_locks.pid AS blocking_pid,
       blocked_activity.query AS blocked_statement
FROM pg_catalog.pg_locks blocked_locks
JOIN pg_catalog.pg_stat_activity blocked_activity ON blocked_activity.pid = blocked_locks.pid
JOIN pg_catalog.pg_locks blocking_locks ON blocking_locks.locktype = blocked_locks.locktype
WHERE NOT blocked_locks.granted;
"

# Fix corrupted database
docker-compose exec db psql -U odoo -d database_name -c "REINDEX DATABASE database_name;"
```

## 🚨 Note Importanti

- **Porta 10016/20016**: Configurate di default, modificabili in `docker-compose.yml`
- **Password Master**: Cambia `to_be_modified` in `etc/odoo.conf`
- **SSL Fix**: Include fix critici per cryptography/pyOpenSSL
- **Backup**: I dati persistono nei volumi Docker anche dopo restart

## 📚 Documentazione

- [Documentazione Odoo 16](https://www.odoo.com/documentation/16.0/)
- [OCA Community Addons](https://github.com/OCA)
- [Docker Compose Reference](https://docs.docker.com/compose/)

## 🤝 Contributi

Pull requests e issue sono benvenuti! Per modifiche importanti, apri prima una issue per discutere cosa vorresti cambiare.

## 📄 Licenza

Questo progetto è sotto licenza MIT - vedi [LICENSE](LICENSE) per dettagli.

---

⭐ **Se questo progetto ti è utile, lascia una stella!** ⭐
