# Quick install

Installazione di Odoo 16 con un solo comando.

(Supporta istanze multiple di Odoo su un singolo server)

Installa [docker](https://docs.docker.com/get-docker/) e [docker-compose](https://docs.docker.com/compose/install/), poi esegui:

```bash
curl -s https://raw.githubusercontent.com/grazrib/docker-compose-odoo16/master/run.sh | sudo bash -s odoo-one 10016 20016
```

per configurare la prima istanza di Odoo @ `localhost:10016` (password master predefinita: `to_be_modified`)

e

```bash
curl -s https://raw.githubusercontent.com/grazrib/docker-compose-odoo16/master/run.sh | sudo bash -s odoo-two 11016 21016
```

per configurare un'altra istanza di Odoo @ `localhost:11016` (password master predefinita: `to_be_modified`)

Parametri:
* Primo parametro (**odoo-one**): Cartella di deploy di Odoo
* Secondo parametro (**10016**): Porta di Odoo
* Terzo parametro (**20016**): Porta live chat

Se `curl` non è trovato, installalo:

```bash
$ sudo apt-get install curl
# oppure
$ sudo yum install curl
```

# Utilizzo

Avvia il container:
```sh
docker-compose up
```

* Poi apri `localhost:10016` per accedere a Odoo 16.0. Se vuoi avviare il server con una porta diversa, modifica **10016** con un altro valore in **docker-compose.yml**:

```yaml
ports:
 - "10016:8069"
```

Esegui il container Odoo in modalità detached (per poter chiudere il terminale senza fermare Odoo):

```sh
docker-compose up -d
```

**Se ottieni problemi di permessi**, modifica i permessi delle cartelle per assicurarti che il container possa accedere alle directory:

```sh
$ git clone https://github.com/grazrib/docker-compose-odoo16.git
$ cd docker-compose-odoo16
$ sudo chmod -R 755 addons
$ sudo chmod -R 755 etc
$ mkdir -p postgresql
$ sudo chmod -R 755 postgresql
$ sudo chown -R 101:101 addons etc
$ sudo chown -R 5432:5432 postgresql
```

Aumenta il numero massimo di file osservati da 8192 (predefinito) a **524288**. Per evitare errori quando eseguiamo più istanze di Odoo. Questo è un passaggio *opzionale*. Questi comandi sono per utenti Ubuntu:

```bash
$ if grep -qF "fs.inotify.max_user_watches" /etc/sysctl.conf; then echo $(grep -F "fs.inotify.max_user_watches" /etc/sysctl.conf); else echo "fs.inotify.max_user_watches = 524288" | sudo tee -a /etc/sysctl.conf; fi
$ sudo sysctl -p    # applica immediatamente la nuova configurazione
```

# Custom addons

La cartella **addons/** contiene addons personalizzati. Inserisci semplicemente i tuoi addons personalizzati se ne hai.

# Configurazione e log di Odoo

* Per modificare la configurazione di Odoo, modifica il file: **etc/odoo.conf**.
* File di log: **etc/odoo-server.log**
* Password predefinita del database (**admin_passwd**) è `to_be_modified`, modificala in [etc/odoo.conf#L60](/etc/odoo.conf#L60)

# Gestione container Odoo

**Esegui Odoo**:

```bash
docker-compose up -d
```

**Riavvia Odoo**:

```bash
docker-compose restart
```

**Ricostruisci Odoo**:

```bash
docker-compose build
```

**Ferma Odoo**:

```bash
docker-compose down
```

# Configurazione OpenLiteSpeed come Proxy

## Configurazione Virtual Host

Crea un Virtual Host in OpenLiteSpeed con la seguente configurazione:

### 1. General Settings
- Document Root: `/var/www/html`
- Index Files: `index.html, index.php`

### 2. Script Handler
Aggiungi un nuovo Script Handler:
- Suffixes: `php`
- Extra Headers: `X-Forwarded-Proto $scheme`

### 3. Rewrite Rules
Nelle **Rewrite Rules** del Virtual Host:

```apache
RewriteEngine On

# Rewrite per Odoo main
RewriteCond %{REQUEST_URI} !^/longpolling/
RewriteRule ^(.*)$ http://127.0.0.1:10016$1 [P,L]

# Rewrite per longpolling (live chat)
RewriteRule ^/longpolling/(.*)$ http://127.0.0.1:20016/longpolling/$1 [P,L]
```

### 4. Context per Proxy
Crea due Context di tipo **Proxy**:

**Context 1 - Odoo Main:**
- Type: `Proxy`
- URI: `/`
- Web Server Type: `HTTP`
- Address: `127.0.0.1:10016`
- Extra Headers:
  ```
  X-Real-IP $remote_addr
  X-Forwarded-For $proxy_add_x_forwarded_for
  X-Forwarded-Proto $scheme
  X-Forwarded-Host $host
  ```

**Context 2 - Longpolling:**
- Type: `Proxy`
- URI: `/longpolling/`
- Web Server Type: `HTTP`
- Address: `127.0.0.1:20016`
- Extra Headers:
  ```
  X-Real-IP $remote_addr
  X-Forwarded-For $proxy_add_x_forwarded_for
  X-Forwarded-Proto $scheme
  X-Forwarded-Host $host
  ```

## Configurazione SSL (Opzionale)

Per abilitare HTTPS, aggiungi un SSL Listener:

### SSL Settings
- Port: `443`
- Secure: `Yes`
- Certificate File: `/path/to/your/cert.pem`
- Private Key File: `/path/to/your/private.key`

### Virtual Host Mapping
- Virtual Host: `your-odoo-vhost`
- Domain: `yourdomain.com, *.yourdomain.com`

## Script di configurazione automatica

Crea il file `configure-openlitespeed.sh`:

```bash
#!/bin/bash
# Script per configurare OpenLiteSpeed per Odoo

DOMAIN=${1:-"localhost"}
VHOST_NAME="odoo"

echo "Configurazione OpenLiteSpeed per Odoo su dominio: $DOMAIN"

# Backup configurazione esistente
sudo cp /usr/local/lsws/conf/httpd_config.conf /usr/local/lsws/conf/httpd_config.conf.backup

# Riavvia OpenLiteSpeed
sudo /usr/local/lsws/bin/lshttpd -t
sudo systemctl restart lsws

echo "Configurazione completata!"
echo "Accedi a OpenLiteSpeed WebAdmin: https://your-server:7080"
echo "Configura manualmente Virtual Host e Context come descritto nel README"
```

# Live chat

Nel [docker-compose.yml](docker-compose.yml), esponiamo la porta **20016** per live-chat sull'host.

La configurazione di **OpenLiteSpeed** per attivare la funzionalità live chat è descritta sopra nella sezione proxy.

# Versioni Docker

* odoo:16.0
* postgres:14.10
* pgadmin4:latest

# Note sui permessi

- I container Odoo e PostgreSQL girano con utenti non-root per sicurezza
- Le cartelle sono configurate con i permessi corretti automaticamente
- I volumi Docker gestiscono la persistenza dei dati

# Troubleshooting

## Problema di connessione al database
```bash
docker-compose logs db
docker-compose logs odoo16
```

## Reset completo
```bash
docker-compose down -v
sudo rm -rf postgresql/ pgadmin-data/
docker-compose up -d
```

## Verifica stato servizi
```bash
docker-compose ps
docker-compose logs -f odoo16
```
