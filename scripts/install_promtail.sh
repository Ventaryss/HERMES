#!/bin/bash

# Ajouter Promtail à docker-compose.yml
cat <<EOL >> ~/LPI/docker/docker-compose.yml

  promtail:
    image: grafana/promtail
    ports:
      - "1514:514"
      - "1514:514/udp"
    volumes:
      - ~/LPI/configs/promtail:/etc/promtail
      - /var/log:/var/log
    command: -config.file=/etc/promtail/promtail-config.yaml
EOL

# Copier le fichier de configuration Promtail
cp ~/LPI/configs/promtail/promtail-config.yaml ~/LPI/configs/promtail/