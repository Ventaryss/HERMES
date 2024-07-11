#!/bin/bash

# Script d'installation pour les clients pour transférer les logs vers le serveur Loki

SERVER_IP="IP_DU_SERVEUR"
LOKI_PORT="3100"

# Installer rsyslog si nécessaire
if ! command -v rsyslogd &> /dev/null
then
    echo "rsyslog non trouvé. Installation..."
    sudo apt-get update
    sudo apt-get install -y rsyslog
else
    echo "rsyslog est déjà installé."
fi

# Configuration de rsyslog pour transférer les logs au serveur Loki
sudo tee /etc/rsyslog.d/01-client-to-server.conf > /dev/null <<EOL
# Forward logs to Loki server
*.* action(type="omfwd" target="$SERVER_IP" port="$LOKI_PORT" protocol="tcp" template="RSYSLOG_SyslogProtocol23Format")
EOL

# Redémarrer rsyslog pour appliquer les changements
sudo systemctl restart rsyslog

echo "Installation terminée. Les logs seront transférés au serveur Loki ($SERVER_IP:$LOKI_PORT)."