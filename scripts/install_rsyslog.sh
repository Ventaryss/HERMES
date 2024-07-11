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

# Cr�er le r�pertoire de configuration rsyslog
mkdir -p ~/LPI/configs/rsyslog

# Cr�er le fichier de configuration rsyslog
sudo tee /etc/rsyslog.d/01-pfsense-to-fluentd.conf > /dev/null <<EOL
# Load necessary modules
module(load="imudp")
module(load="omfwd")

# Listen for UDP syslog messages on port 514
input(type="imudp" port="514")

# Forward all logs to Fluentd
*.* action(type="omfwd" target="127.0.0.1" port="24224" protocol="tcp" template="RSYSLOG_SyslogProtocol23Format")
EOL

# Red�marrer rsyslog pour appliquer la nouvelle configuration
sudo systemctl restart rsyslog