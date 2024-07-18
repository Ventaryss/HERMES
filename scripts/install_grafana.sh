#!/bin/bash

# Créer le répertoire de configuration Grafana
mkdir -p ~/LPI/dashboards_grafana/grafana
mkdir -p ~/LPI/configs/grafana/provisioning/dashboards

# Créer un fichier de dashboard par défaut
cat <<EOL > ~/LPI/dashboards_grafana/grafana/default_dashboard.json
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
cat <<EOL > ~/LPI/configs/grafana/provisioning/dashboards/dashboard.yaml
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

# Use the specific docker-compose file for Grafana
docker compose -f ~/LPI/docker/docker-compose-grafana.yml up -d
