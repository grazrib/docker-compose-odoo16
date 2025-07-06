#!/bin/bash
DESTINATION=$1
PORT=$2
CHAT=$3

# Verifica parametri
if [ -z "$DESTINATION" ] || [ -z "$PORT" ] || [ -z "$CHAT" ]; then
    echo "Uso: $0 <directory> <porta_odoo> <porta_chat>"
    echo "Esempio: $0 odoo-one 10016 20016"
    exit 1
fi

echo "Configurazione Odoo con parametri:"
echo "Directory: $DESTINATION"
echo "Porta Odoo: $PORT"
echo "Porta Chat: $CHAT"

# Clona directory Odoo
git clone --depth=1 https://github.com/grazrib/docker-compose-odoo16.git $DESTINATION
rm -rf $DESTINATION/.git

# Crea cartelle necessarie
mkdir -p $DESTINATION/postgresql
mkdir -p $DESTINATION/addons
mkdir -p $DESTINATION/etc

# Imposta permessi corretti
sudo chown -R 101:101 $DESTINATION/addons $DESTINATION/etc
sudo chown -R 5432:5432 $DESTINATION/postgresql
sudo chmod -R 755 $DESTINATION

# Configurazione sistema
if grep -qF "fs.inotify.max_user_watches" /etc/sysctl.conf; then 
    echo $(grep -F "fs.inotify.max_user_watches" /etc/sysctl.conf)
else 
    echo "fs.inotify.max_user_watches = 524288" | sudo tee -a /etc/sysctl.conf
fi
sudo sysctl -p

# Sostituisci porte nel docker-compose.yml
sed -i 's/10016/'$PORT'/g' $DESTINATION/docker-compose.yml
sed -i 's/20016/'$CHAT'/g' $DESTINATION/docker-compose.yml

# Avvia Odoo
cd $DESTINATION
docker-compose up -d

echo ""
echo "✅ Odoo avviato con successo!"
echo "🌐 URL Odoo: http://localhost:$PORT"
echo "🔑 Password Master: to_be_modified"
echo "💬 Porta Live Chat: $CHAT"
echo "🔧 PgAdmin: http://localhost:5050"
echo ""
echo "Per verificare lo stato:"
echo "docker-compose ps"
echo ""
echo "Per vedere i log:"
echo "docker-compose logs -f"
