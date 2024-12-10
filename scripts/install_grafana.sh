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

# Créer les répertoires nécessaires avec les permissions adéquates
mkdir -p "${BASE_DIR}/grafana-storage"
check_command "Création du répertoire grafana-storage"
sudo chown -R "$(id -u):$(id -g)" "${BASE_DIR}/grafana-storage"
sudo chmod -R 750 "${BASE_DIR}/grafana-storage"

# Créer le répertoire de configuration Grafana
mkdir -p "${BASE_DIR}/configs/grafana/provisioning/dashboards"
check_command "Création du répertoire de configuration Grafana"

# Créer un fichier de provisioning pour Grafana
cat <<EOL > "${BASE_DIR}/configs/grafana/provisioning/dashboards/dashboard.yaml"
apiVersion: 1
providers:
  - name: 'default'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: true
    updateIntervalSeconds: 30
    options:
      path: /var/lib/grafana/dashboards
EOL
check_command "Création du fichier de provisioning pour Grafana"

# Créer le fichier de configuration des datasources
mkdir -p "${BASE_DIR}/configs/grafana/provisioning/datasources"
check_command "Création du répertoire des datasources"

# Récupérer le token InfluxDB à partir de l'environnement
INFLUXDB_TOKEN=$(influx auth list --json | jq -r '.[0].token')
check_command "Récupération du token InfluxDB"

cat <<EOF > "${BASE_DIR}/configs/grafana/provisioning/datasources/datasource.yaml"
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: true
  - name: Loki
    type: loki
    access: proxy
    url: http://loki:3100
    editable: true
  - name: InfluxDB
    type: influxdb
    access: proxy
    url: http://influxdb:8086
    jsonData:
      organization: lpi
      defaultBucket: logs
      version: Flux
    secureJsonData:
      token: ${INFLUXDB_TOKEN}
    editable: true
EOF
check_command "Création du fichier de configuration des datasources"

# Créer un Dockerfile pour inclure les dashboards
cat <<EOF > "${BASE_DIR}/docker/grafana/Dockerfile"
FROM grafana/grafana:latest
COPY dashboards/ /var/lib/grafana/dashboards
COPY configs/grafana/provisioning/dashboards /etc/grafana/provisioning/dashboards
COPY configs/grafana/provisioning/datasources /etc/grafana/provisioning/datasources
EOF
check_command "Création du Dockerfile pour Grafana"

# Copier les dashboards JSON fournis dans le répertoire des dashboards
cp "${HOME}/dashboards_grafana/"*.json "${BASE_DIR}/dashboards_grafana/grafana/"
check_command "Copie des dashboards JSON"

# Utiliser le fichier docker-compose spécifique pour Grafana
docker compose -f "${BASE_DIR}/docker/docker-compose-grafana.yml" up -d --build
check_command "Démarrage de Grafana avec Docker Compose"

# Configuration de Logrotate pour l'archivage des logs
LOGROTATE_CONF="/etc/logrotate.d/grafana_logs"
ARCHIVE_DIR="/path/to/Archives_Logs/grafana_logs_archives/"

# S'assurer que le répertoire d'archives existe
sudo mkdir -p "$ARCHIVE_DIR"
sudo chown grafana:grafana "$ARCHIVE_DIR"
sudo chmod 750 "$ARCHIVE_DIR"

sudo tee "$LOGROTATE_CONF" > /dev/null <<EOL
/var/log/grafana/*.log {
    weekly
    missingok
    rotate 4
    compress
    delaycompress
    dateext
    dateformat _%Y%m%d
    olddir ${ARCHIVE_DIR}
    create 640 grafana grafana
    notifempty
    sharedscripts
    postrotate
        systemctl restart grafana-server
    endscript
}
EOL
check_command "Configuration de Logrotate pour Grafana"

log "Installation et configuration de Grafana terminées avec succès."
