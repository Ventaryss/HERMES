#!/bin/bash

# Cr�er le r�pertoire de configuration Grafana
mkdir -p ~/LPI/dashboards/grafana

# Cr�er un fichier de dashboard par d�faut
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