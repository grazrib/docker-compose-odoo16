#!/bin/bash
DESTINATION=$1
PORT=$2
CHAT=$3

# Verifica parametri
if [ -z "$DESTINATION" ] || [ -z "$PORT" ] || [ -z "$CHAT" ]; then
    echo "❌ Parametri mancanti!"
    echo "💡 Uso: $0 <directory> <porta_odoo> <porta_chat>"
    echo "📝 Esempio: $0 odoo-one 10016 20016"
    exit 1
fi

echo "🚀 Configurazione Odoo 16 Docker"
echo "📁 Directory: $DESTINATION"
echo "🌐 Porta Odoo: $PORT"
echo "💬 Porta Chat: $CHAT"
echo ""

# Clona repository
echo "📥 Download files..."
git clone --depth=1 https://github.com/grazrib/docker-compose-odoo16.git $DESTINATION
rm -rf $DESTINATION/.git

# Crea directory necessarie
mkdir -p $DESTINATION/addons
mkdir -p $DESTINATION/etc

# Imposta permessi corretti
echo "🔧 Configurazione permessi..."
sudo chmod -R 755 $DESTINATION
sudo chmod +x $DESTINATION/entrypoint.sh

# Configura sistema per più istanze
echo "⚙️ Configurazione sistema..."
if grep -qF "fs.inotify.max_user_watches" /etc/sysctl.conf; then 
    echo "✅ fs.inotify.max_user_watches già configurato"
else 
    echo "fs.inotify.max_user_watches = 524288" | sudo tee -a /etc/sysctl.conf
    echo "✅ fs.inotify.max_user_watches configurato"
fi
sudo sysctl -p > /dev/null

# Sostituisci porte
echo "🔄 Configurazione porte..."
sed -i 's/10016/'$PORT'/g' $DESTINATION/docker-compose.yml
sed -i 's/20016/'$CHAT'/g' $DESTINATION/docker-compose.yml

# Avvia servizi
echo "🔨 Avvio Docker Compose..."
cd $DESTINATION
docker-compose up -d

echo ""
echo "✅ Odoo 16 installato con successo!"
echo ""
echo "🌐 Accessi disponibili:"
echo "   Odoo:    http://localhost:$PORT"
echo "   PgAdmin: http://localhost:5050"
echo ""
echo "🔑 Credenziali:"
echo "   Master Password: to_be_modified"
echo "   PgAdmin Email:   admin@example.com"
echo "   PgAdmin Pass:    admin123"
echo ""
echo "📊 Comandi utili:"
echo "   Status:   docker-compose ps"
echo "   Logs:     docker-compose logs -f odoo16"
echo "   Stop:     docker-compose down"
echo "   Restart:  docker-compose restart"
echo ""

# Verifica avvio
echo "⏳ Verifica avvio (30 secondi)..."
sleep 30

if curl -s http://localhost:$PORT >/dev/null 2>&1; then
    echo "🎉 Odoo è online e funzionante!"
else
    echo "⚠️  Odoo potrebbe essere ancora in avvio..."
    echo "🔍 Controlla i log: docker-compose logs -f odoo16"
fi
