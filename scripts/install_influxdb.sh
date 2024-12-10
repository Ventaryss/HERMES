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

# Utiliser le fichier docker-compose spécifique pour InfluxDB
docker compose -f "${BASE_DIR}/docker/docker-compose-influxdb.yml" up -d
check_command "Démarrage d'InfluxDB avec Docker Compose"

# Attendre qu'InfluxDB démarre
log "Attente du démarrage d'InfluxDB..."
sleep 10

# Vérifier si l'outil CLI d'InfluxDB est installé
if ! command -v influx &> /dev/null; then
    log "InfluxDB CLI introuvable. Veuillez l'installer pour continuer."
    exit 1
fi

# Définir les paramètres InfluxDB
ORG_NAME="lpi"
BUCKET_NAME="logs"
INFLUXDB_USER="admin"
INFLUXDB_PASSWORD="adminadmin"
ADMIN_TOKEN="your_admin_token"  # Assurez-vous que ce token est correctement configuré dans InfluxDB

# Créer une organisation InfluxDB
influx org create -n "$ORG_NAME" --host http://localhost:8086 -t "$ADMIN_TOKEN"
check_command "Création de l'organisation InfluxDB"

# Créer un bucket InfluxDB (base de données)
influx bucket create -n "$BUCKET_NAME" -o "$ORG_NAME" --host http://localhost:8086 -t "$ADMIN_TOKEN"
check_command "Création du bucket InfluxDB"

# Créer un token de lecture/écriture pour le bucket
TOKEN=$(influx auth create --org "$ORG_NAME" --user "$INFLUXDB_USER" --read-bucket "$BUCKET_NAME" --write-bucket "$BUCKET_NAME" --host http://localhost:8086 -t "$ADMIN_TOKEN" | grep "Token" | awk '{print $2}')
check_command "Création du token d'authentification InfluxDB"

# Stocker le token dans un fichier pour une utilisation ultérieure
echo "$TOKEN" > "${BASE_DIR}/influxdb_token.txt"
chmod 600 "${BASE_DIR}/influxdb_token.txt"
check_command "Stockage du token InfluxDB"

log "InfluxDB a été configuré avec succès."
log "Organisation : $ORG_NAME"
log "Bucket : $BUCKET_NAME"
log "Token stocké dans ${BASE_DIR}/influxdb_token.txt"

# Configuration de Logrotate pour l'archivage des logs
LOGROTATE_CONF="/etc/logrotate.d/influxdb_logs"
ARCHIVE_DIR="/path/to/Archives_Logs/influxdb_logs_archives/"

# S'assurer que le répertoire d'archives existe
sudo mkdir -p "$ARCHIVE_DIR"
sudo chown influxdb:influxdb "$ARCHIVE_DIR"
sudo chmod 750 "$ARCHIVE_DIR"

sudo tee "$LOGROTATE_CONF" > /dev/null <<EOL
/var/log/influxdb/*.log {
    weekly
    missingok
    rotate 4
    compress
    delaycompress
    dateext
    dateformat _%Y%m%d
    olddir ${ARCHIVE_DIR}
    create 640 influxdb influxdb
    notifempty
    sharedscripts
    postrotate
        systemctl restart influxdb
    endscript
}
EOL
check_command "Configuration de Logrotate pour InfluxDB"

log "Configuration d'InfluxDB et de Logrotate terminée avec succès."
