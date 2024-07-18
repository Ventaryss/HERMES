#!/bin/bash

# Démarrer InfluxDB via Docker Compose
cd ~/lpi-monitoring/docker
docker compose -f ~/lpi-monitoring/docker/docker-compose-influxdb.yml up -d
