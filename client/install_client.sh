#!/bin/bash

# Installer rsyslog si non installé
if ! command -v rsyslogd &> /dev/null
then
    echo "rsyslog non trouvé. Installation..."
    sudo apt-get update
    sudo apt-get install -y rsyslog rsyslog-relp
else
    echo "rsyslog est déjà installé."
fi

# Configurer rsyslog pour transférer les logs au serveur central
sudo tee /etc/rsyslog.d/forward-logs.conf > /dev/null <<EOL
*.* action(type="omfwd" target="SERVER_IP" port="514" protocol="udp")
EOL

# Redémarrer rsyslog pour appliquer la nouvelle configuration
sudo systemctl restart rsyslog