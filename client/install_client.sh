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

# Définir l'adresse IP du serveur
SERVER_IP="${SERVER_IP:-0.0.0.0}"  # Utilisez une variable d'environnement ou la valeur par défaut

# Fonction pour installer Node Exporter
install_node_exporter() {
    if [[ "$(uname)" == "Linux" ]]; then
        log "Installation de Node Exporter sur Linux"
        local version="1.3.1"
        local filename="node_exporter-${version}.linux-amd64.tar.gz"
        
        curl -LO "https://github.com/prometheus/node_exporter/releases/download/v${version}/${filename}"
        check_command "Téléchargement de Node Exporter"
        
        echo "9468d0796f13bb310b63c9870de0ffec8c68e5a472895be568e2e0a3e2b8a242 ${filename}" | sha256sum -c
        check_command "Vérification de l'intégrité de Node Exporter"
        
        tar xvf "${filename}"
        check_command "Extraction de Node Exporter"
        
        sudo mv "node_exporter-${version}.linux-amd64/node_exporter" /usr/local/bin/
        rm -rf "node_exporter-${version}.linux-amd64"*
        
        sudo useradd --no-create-home --shell /bin/false node_exporter
        
        sudo tee /etc/systemd/system/node_exporter.service > /dev/null <<EOL
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=node_exporter
ExecStart=/usr/local/bin/node_exporter
Restart=always

[Install]
WantedBy=multi-user.target
EOL
        check_command "Création du service systemd pour Node Exporter"

        sudo systemctl daemon-reload
        sudo systemctl start node_exporter
        sudo systemctl enable node_exporter
        check_command "Démarrage du service Node Exporter"

    elif [[ "$(uname)" == "Windows_NT" ]]; then
        log "Installation de Node Exporter sur Windows n'est pas supportée par ce script."
        exit 1
    else
        log "Système d'exploitation non supporté."
        exit 1
    fi
}

# Demander à l'utilisateur s'il veut installer Node Exporter
read -p "Voulez-vous installer Node Exporter (y/n) ? " install_node_exporter_choice

# Installer rsyslog si non installé
if ! command -v rsyslogd &> /dev/null; then
    log "rsyslog non trouvé. Installation..."
    sudo apt-get update
    sudo apt-get install -y rsyslog rsyslog-relp
    check_command "Installation de rsyslog"
else
    log "rsyslog est déjà installé."
fi

# Configurer rsyslog pour transférer les logs au serveur central
sudo tee /etc/rsyslog.d/forward-logs.conf > /dev/null <<EOL
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
*.* action(type="omfwd" target="${SERVER_IP}" port="514" protocol="tcp" template="t_detailed")
EOL
check_command "Configuration de rsyslog pour transférer les logs"

# Redémarrer rsyslog pour appliquer la nouvelle configuration
sudo systemctl restart rsyslog
check_command "Redémarrage de rsyslog"

# Installer Node Exporter si l'utilisateur le souhaite
if [[ "$install_node_exporter_choice" == "y" ]]; then
    install_node_exporter
fi

log "Configuration terminée avec succès."
