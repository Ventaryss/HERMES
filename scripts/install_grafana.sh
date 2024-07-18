#!/bin/bash

# Créer le répertoire de configuration Grafana
mkdir -p ~/lpi-monitoring/dashboards_grafana/grafana
mkdir -p ~/lpi-monitoring/configs/grafana/provisioning/dashboards

# Créer un fichier de dashboard par défaut
cat <<EOL > ~/lpi-monitoring/dashboards_grafana/grafana/default_dashboard.json
{
  "dashboard": {
    "id": null,
    "uid": "default",
    "title": "Default Dashboard",
    "tags": [],
    "timezone": "browser",
    "schemaVersion": 16,
    "version": 0,
    "panels": []
  }
}
EOL

# Créer un fichier de provisioning pour Grafana
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
      path: /etc/grafana/provisioning/dashboards
EOL

# Définir les permissions pour l'utilisateur root
sudo chown -R root:root ~/lpi-monitoring/dashboards_grafana/grafana
sudo chown -R root:root ~/lpi-monitoring/configs/grafana/provisioning/dashboards
sudo chown root:root ~/lpi-monitoring/dashboards_grafana/grafana/default_dashboard.json
sudo chown root:root ~/lpi-monitoring/configs/grafana/provisioning/dashboards/dashboard.yaml

# Utiliser le fichier docker-compose spécifique pour Grafana
docker compose -f ~/lpi-monitoring/docker/docker-compose-grafana.yml up -d
