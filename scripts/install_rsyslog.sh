#!/bin/bash

# Activer le mode strict pour bash
set -euo pipefail

# Fonction de journalisation
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Fonction pour vérifier l'exécution des commandes
check_command() {
    if [[ $? -ne 0 ]]; then
        log "Erreur : $1 a échoué." >&2
        exit 1
    fi
}

# Définir le répertoire de base
BASE_DIR="${HOME}/lpi-monitoring"

# Installer rsyslog si non installé
if ! command -v rsyslogd &> /dev/null
then
    log "rsyslog non trouvé. Installation..."
    sudo apt-get update
    sudo apt-get install -y rsyslog rsyslog-relp
    check_command "Installation de rsyslog"
else
    log "rsyslog est déjà installé."
fi

# Créer le répertoire de configuration rsyslog
mkdir -p "${BASE_DIR}/configs/rsyslog"
check_command "Création du répertoire de configuration rsyslog"

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
if \$hostname contains "pfSense" then {
    action(type="omfile" file="/var/log/pfsense/pfsense.log")
    action(type="omfwd" target="127.0.0.1" port="24224" protocol="tcp" template="t_detailed")
    stop
}

# Listen for Stormshield syslog messages on port 5141
input(type="imudp" port="5141")

# Redirect Stormshield logs to a specific file
if \$hostname contains "stormshield" then {
    action(type="omfile" file="/var/log/stormshield/stormshield.log")
    action(type="omfwd" target="127.0.0.1" port="24225" protocol="tcp" template="t_detailed")
    stop
}

# Listen for Palo Alto syslog messages on port 5142
input(type="imudp" port="5142")

# Redirect Palo Alto logs to a specific file
if \$hostname contains "paloalto" then {
    action(type="omfile" file="/var/log/paloalto/paloalto.log")
    action(type="omfwd" target="127.0.0.1" port="24226" protocol="tcp" template="t_detailed")
    stop
}
EOL
check_command "Création du fichier de configuration rsyslog"

# Redémarrer rsyslog pour appliquer la nouvelle configuration
sudo systemctl restart rsyslog
check_command "Redémarrage de rsyslog"

log "Configuration de rsyslog terminée avec succès."
