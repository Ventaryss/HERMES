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
mkdir -p ~/lpi-monitoring/configs/rsyslog

# Créer le fichier de configuration rsyslog
sudo tee /etc/rsyslog.d/01-pfsense-to-fluentd.conf > /dev/null <<EOL
# Load necessary modules
module(load="imudp")
module(load="omfwd")

# Listen for UDP syslog messages on port 514
input(type="imudp" port="514")

# Forward all logs to Fluentd
template(name="t_detailed" type="list") {
    constant(value="{")
    constant(value="\"Time\":\"") property(name="timereported" dateFormat="rfc3339")
    constant(value="\",\"Host\":\"") property(name="hostname")
    constant(value="\",\"Program\":\"") property(name="programname")
    constant(value="[") property(name="procid")
    constant(value="]\",\"Source IP\":\"") property(name="source")
    constant(value="\",\"Destination IP\":\"") property(name="destination")
    constant(value="\",\"Source Port\":\"") property(name="srcport")
    constant(value="\",\"Destination Port\":\"") property(name="dstport")
    constant(value="\",\"Protocol\":\"") property(name="protocol")
    constant(value="\",\"User\":\"") property(name="username")
    constant(value="\",\"URL\":\"") property(name="url")
    constant(value="\",\"Action\":\"") property(name="action")
    constant(value="\",\"Bytes Sent\":\"") property(name="sentbytecount")
    constant(value="\",\"Bytes Received\":\"") property(name="receivedbytecount")
    constant(value="\",\"Rule\":\"") property(name="rule")
    constant(value="\",\"Reason\":\"") property(name="reason")
    constant(value="\"}\n")
}

# Redirect pfSense logs to a specific file
:hostname, contains, "pfSense" /var/log/pfsense/pfsense.log

# Redirect client logs to /var/log/client_logs
if \$fromhost-ip != '127.0.0.1' and \$hostname !contains "pfSense" then /var/log/client_logs/client.log

# Forward all logs to Fluentd using the custom template
*.* action(type="omfwd" target="127.0.0.1" port="24224" protocol="tcp" template="t_detailed")
EOL

# Créer le répertoire pour les logs des clients
sudo mkdir -p /var/log/client_logs

# Redémarrer rsyslog pour appliquer la nouvelle configuration
sudo systemctl restart rsyslog
