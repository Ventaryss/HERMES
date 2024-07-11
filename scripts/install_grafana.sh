#!/bin/bash

# Création des répertoires nécessaires
mkdir -p ~/LPI/grafana-storage ~/LPI/grafana-provisioning

# Ajouter Grafana à docker-compose.yml
cat <<EOL >> ~/LPI/docker/docker-compose.yml

  grafana:
    image: grafana/grafana
    ports:
      - 3000:3000
    volumes:
      - ~/LPI/grafana-storage:/var/lib/grafana
      - ~/LPI/grafana-provisioning:/etc/grafana/provisioning
EOL

# Copier les templates de dashboards
cp ~/LPI/dashboards/* ~/LPI/grafana-provisioning/dashboards/