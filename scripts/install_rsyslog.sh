#!/bin/bash

# Installer rsyslog si nécessaire
if ! command -v rsyslogd &> /dev/null
then
    echo "rsyslog non trouvé. Installation..."
    sudo apt-get update
    sudo apt-get install -y rsyslog
else
    echo "rsyslog est déjà installé."
fi

# Copier le fichier de configuration Rsyslog
sudo cp ~/LPI/configs/rsyslog/01-pfsense-to-fluentd.conf /etc/rsyslog.d/

# Redémarrer rsyslog pour appliquer les changements
sudo systemctl restart rsyslog