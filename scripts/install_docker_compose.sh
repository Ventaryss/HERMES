#!/bin/bash

# Installer Docker Compose si non installé
if ! command -v docker compose &> /dev/null
then
    echo "Docker Compose non trouvé. Installation..."
    sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
else
    echo "Docker Compose est déjà installé."
fi