#!/bin/bash

# Créer les répertoires nécessaires avec les permissions adéquates
mkdir -p ~/lpi-monitoring/grafana-storage/dashboards
sudo chown -R $(whoami):$(whoami) ~/lpi-monitoring/grafana-storage
sudo chmod -R 777 ~/lpi-monitoring/grafana-storage

# Créer le répertoire de configuration Grafana
mkdir -p ~/lpi-monitoring/configs/grafana/provisioning/dashboards
mkdir -p ~/lpi-monitoring/configs/grafana/provisioning/datasources

# Créer un fichier de provisioning pour les dashboards Grafana
cat <<EOL > ~/lpi-monitoring/configs/grafana/provisioning/dashboards/dashboard.yaml
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

# Créer le fichier de configuration des datasources
cat <<EOF > ~/lpi-monitoring/configs/grafana/provisioning/datasources/datasource.yaml
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
      version: Flux
      organization: lpi
      defaultBucket: logs
    secureJsonData:
      token: your_influxdb_token
    editable: true
EOF

# Copier les dashboards JSON fournis dans le répertoire des dashboards
cp ~/lpi-monitoring/dashboards_grafana/*.json ~/lpi-monitoring/grafana-storage/dashboards/

# Utiliser le fichier docker-compose spécifique pour Grafana
docker compose -f ~/lpi-monitoring/docker/docker-compose-grafana.yml up -d --build
