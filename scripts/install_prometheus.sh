#!/bin/bash

# Création des répertoires nécessaires
mkdir -p ~/LPI/prometheus-storage

# Ajouter Prometheus à docker-compose.yml
cat <<EOL >> ~/LPI/docker/docker-compose.yml

  prometheus:
    image: prom/prometheus
    ports:
      - 9090:9090
    volumes:
      - ~/LPI/prometheus-storage:/prometheus
      - ~/LPI/configs/prometheus:/etc/prometheus
EOL

# Copier le fichier de configuration Prometheus
cp ~/LPI/configs/prometheus/prometheus.yml ~/LPI/configs/prometheus/