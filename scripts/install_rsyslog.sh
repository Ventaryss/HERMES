#!/bin/bash

# Installer rsyslog si n�cessaire
if ! command -v rsyslogd &> /dev/null
then
    echo "rsyslog non trouv�. Installation..."
    sudo apt-get update
    sudo apt-get install -y rsyslog
else
    echo "rsyslog est d�j� install�."
fi

# Copier le fichier de configuration Rsyslog
sudo cp ~/LPI/configs/rsyslog/01-pfsense-to-fluentd.conf /etc/rsyslog.d/

# Red�marrer rsyslog pour appliquer les changements
sudo systemctl restart rsyslog