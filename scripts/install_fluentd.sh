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

# Créer le répertoire de configuration Fluentd
mkdir -p "${BASE_DIR}/configs/fluentd"
check_command "Création du répertoire de configuration Fluentd"

# Créer le fichier de configuration Fluentd
cat <<EOL > "${BASE_DIR}/configs/fluentd/fluent.conf"
# Configuration Fluentd ici...
EOL
check_command "Création du fichier de configuration Fluentd"

# Utiliser le fichier docker-compose spécifique pour Fluentd
docker compose -f "${BASE_DIR}/docker/docker-compose-fluentd.yml" up -d
check_command "Démarrage de Fluentd avec Docker Compose"

# Configuration de Logrotate pour l'archivage des logs
LOGROTATE_CONF="/etc/logrotate.d/fluentd_logs"
ARCHIVE_DIR="/path/to/Archives_Logs/fluentd_logs_archives/"

# S'assurer que le répertoire d'archives existe
sudo mkdir -p "$ARCHIVE_DIR"
sudo chown root:adm "$ARCHIVE_DIR"
sudo chmod 750 "$ARCHIVE_DIR"

sudo tee "$LOGROTATE_CONF" > /dev/null <<EOL
/var/log/fluentd/*.log {
    weekly
    missingok
    rotate 4
    compress
    delaycompress
    dateext
    dateformat _%Y%m%d
    olddir ${ARCHIVE_DIR}
    create 640 root adm
    notifempty
    sharedscripts
    postrotate
        systemctl restart docker
    endscript
}
EOL
check_command "Configuration de Logrotate pour Fluentd"

log "Installation et configuration de Fluentd terminées avec succès."
