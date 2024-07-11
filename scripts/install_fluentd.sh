#!/bin/bash

# Création des répertoires nécessaires
mkdir -p ~/LPI/pfsense-logs

# Ajouter Fluentd à docker-compose.yml
cat <<EOL >> ~/LPI/docker/docker-compose.yml

  fluentd:
    image: grafana/fluent-plugin-loki:latest
    ports:
      - 24224:24224
      - 24224:24224/udp
    volumes:
      - ~/LPI/configs/fluentd:/fluentd/etc
      - ~/LPI/pfsense-logs:/var/log/pfsense
    command: fluentd -c /fluentd/etc/fluent.conf
EOL

# Copier le fichier de configuration Fluentd
cp ~/LPI/configs/fluentd/fluent.conf ~/LPI/configs/fluentd/