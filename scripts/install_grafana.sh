#!/bin/bash

# Créer le répertoire de configuration Grafana
mkdir -p ~/LPI/dashboards/grafana

# Créer un fichier de dashboard par défaut
cat <<EOL > ~/LPI/dashboards/grafana/default_dashboard.json
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