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

# Créer le répertoire de configuration rsyslog
mkdir -p ~/LPI/configs/rsyslog

# Créer le fichier de configuration rsyslog
sudo tee /etc/rsyslog.d/01-pfsense-to-fluentd.conf > /dev/null <<EOL
# Load necessary modules
module(load="imudp")
module(load="omfwd")

# Listen for UDP syslog messages on port 514
input(type="imudp" port="514")

# Forward all logs to Fluentd
*.* action(type="omfwd" target="127.0.0.1" port="24224" protocol="tcp" template="RSYSLOG_SyslogProtocol23Format")
EOL

# Redémarrer rsyslog pour appliquer la nouvelle configuration
sudo systemctl restart rsyslog