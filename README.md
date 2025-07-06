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

### Modifica `etc/odoo.conf`:
```ini
[options]
addons_path = /mnt/extra-addons
data_dir = /etc/odoo
admin_passwd = your_secure_password

# Performance tuning
workers = 4
max_cron_threads = 2
limit_memory_soft = 2147483648
limit_memory_hard = 2684354560

# Development
dev_mode = reload
log_level = debug
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

## 📊 Monitoraggio

```bash
# Health check manuale
curl -I http://localhost:10016

# Database connection test
docker-compose exec db psql -U odoo -c "SELECT version();"

# Odoo modules list
docker-compose exec odoo16 odoo shell -d your_db --no-http
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
