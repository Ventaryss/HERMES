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
mkdir -p "${BASE_DIR}/prometheus-storage"
check_command "Création du répertoire prometheus-storage"
sudo chown -R "$(id -u):$(id -g)" "${BASE_DIR}/prometheus-storage"
sudo chmod -R 750 "${BASE_DIR}/prometheus-storage"

# Créer le répertoire de configuration Prometheus
mkdir -p "${BASE_DIR}/configs/prometheus"
check_command "Création du répertoire de configuration Prometheus"

# Créer un fichier de configuration Prometheus par défaut
cat <<EOL > "${BASE_DIR}/configs/prometheus/prometheus.yml"
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node'
    static_configs:
      - targets: ['node-exporter:9100']

  - job_name: 'influxdb'
    static_configs:
      - targets: ['influxdb:8086']

  - job_name: 'grafana'
    static_configs:
      - targets: ['grafana:3000']

  - job_name: 'loki'
    static_configs:
      - targets: ['loki:3100']

  - job_name: 'promtail'
    static_configs:
      - targets: ['promtail:9080']
EOL
check_command "Création du fichier de configuration Prometheus"

# Utiliser le fichier docker-compose spécifique pour Prometheus
docker compose -f "${BASE_DIR}/docker/docker-compose-prometheus.yml" up -d
check_command "Démarrage de Prometheus avec Docker Compose"

# Configuration de Logrotate pour l'archivage des logs
LOGROTATE_CONF="/etc/logrotate.d/prometheus_logs"
ARCHIVE_DIR="/path/to/Archives_Logs/prometheus_logs_archives/"

# S'assurer que le répertoire d'archives existe
sudo mkdir -p "$ARCHIVE_DIR"
sudo chown prometheus:prometheus "$ARCHIVE_DIR"
sudo chmod 750 "$ARCHIVE_DIR"

sudo tee "$LOGROTATE_CONF" > /dev/null <<EOL
/var/log/prometheus/*.log {
    weekly
    missingok
    rotate 4
    compress
    delaycompress
    dateext
    dateformat _%Y%m%d
    olddir ${ARCHIVE_DIR}
    create 640 prometheus prometheus
    notifempty
    sharedscripts
    postrotate
        systemctl restart prometheus
    endscript
}
EOL
check_command "Configuration de Logrotate pour Prometheus"

log "Installation et configuration de Prometheus terminées avec succès."
