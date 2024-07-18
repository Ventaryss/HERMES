#!/bin/bash

# Démarrer InfluxDB via Docker Compose
cd ~/lpi-monitoring/docker
docker-compose -f docker-compose-influxdb.yml up -d
