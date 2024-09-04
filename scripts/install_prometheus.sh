#!/bin/bash

# Fonction pour vérifier l'exécution des commandes
check_command() {
    if [ $? -ne 0 ]; then
        echo "Erreur : $1 a échoué." >&2
        exit 1
    fi
}

# Créer les répertoires nécessaires avec les permissions adéquates
mkdir -p ~/lpi-monitoring/prometheus-storage
check_command "Création du répertoire prometheus-storage"
sudo chown -R $(whoami):$(whoami) ~/lpi-monitoring/prometheus-storage
sudo chmod -R 777 ~/lpi-monitoring/prometheus-storage

# Créer le répertoire de configuration Prometheus
mkdir -p ~/lpi-monitoring/configs/prometheus
check_command "Création du répertoire de configuration Prometheus"

# Créer un fichier de configuration Prometheus par défaut
cat <<EOL > ~/lpi-monitoring/configs/prometheus/prometheus.yml
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
docker compose -f ~/lpi-monitoring/docker/docker-compose-prometheus.yml up -d
check_command "Démarrage de Prometheus avec Docker Compose"

# Configuration de Logrotate pour l'archivage des logs
LOGROTATE_CONF="/etc/logrotate.d/prometheus_logs"
sudo tee $LOGROTATE_CONF > /dev/null <<EOL
/var/log/prometheus/*.log {
    weekly
    missingok
    rotate 4
    compress
    delaycompress
    dateext
    dateformat _Semaine_%V
    olddir /path/to/Archives_Logs/prometheus_logs_archives/
    create 640 prometheus prometheus
    notifempty
    sharedscripts
    postrotate
        systemctl restart prometheus
    endscript
}
EOL
check_command "Configuration de Logrotate pour Prometheus"
