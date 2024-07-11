#!/bin/bash

# Installer rsyslog si non install�
if ! command -v rsyslogd &> /dev/null
then
    echo "rsyslog non trouv�. Installation..."
    sudo apt-get update
    sudo apt-get install -y rsyslog rsyslog-relp
else
    echo "rsyslog est d�j� install�."
fi

# Configurer rsyslog pour transf�rer les logs au serveur central
sudo tee /etc/rsyslog.d/forward-logs.conf > /dev/null <<EOL
*.* action(type="omfwd" target="SERVER_IP" port="514" protocol="udp")
EOL

# Red�marrer rsyslog pour appliquer la nouvelle configuration
sudo systemctl restart rsyslog