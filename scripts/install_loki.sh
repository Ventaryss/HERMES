#!/bin/bash

# Création des répertoires nécessaires
mkdir -p ~/LPI/loki-storage

# Ajouter Loki à docker-compose.yml
cat <<EOL >> ~/LPI/docker/docker-compose.yml

  loki:
    image: grafana/loki
    ports:
      - "3100:3100"
    volumes:
      - ~/LPI/loki-storage:/loki
      - ~/LPI/configs/loki:/etc/loki
    command: -config.file=/etc/loki/loki-config.yaml
EOL

# Copier le fichier de configuration Loki
cp ~/LPI/configs/loki/loki-config.yaml ~/LPI/configs/loki/