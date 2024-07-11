#!/bin/bash

# Script d'installation pour les clients pour transf�rer les logs vers le serveur Loki

SERVER_IP="IP_DU_SERVEUR"
LOKI_PORT="3100"

# Installer rsyslog si n�cessaire
if ! command -v rsyslogd &> /dev/null
then
    echo "rsyslog non trouv�. Installation..."
    sudo apt-get update
    sudo apt-get install -y rsyslog
else
    echo "rsyslog est d�j� install�."
fi

# Configuration de rsyslog pour transf�rer les logs au serveur Loki
sudo tee /etc/rsyslog.d/01-client-to-server.conf > /dev/null <<EOL
# Forward logs to Loki server
*.* action(type="omfwd" target="$SERVER_IP" port="$LOKI_PORT" protocol="tcp" template="RSYSLOG_SyslogProtocol23Format")
EOL

# Red�marrer rsyslog pour appliquer les changements
sudo systemctl restart rsyslog

echo "Installation termin�e. Les logs seront transf�r�s au serveur Loki ($SERVER_IP:$LOKI_PORT)."