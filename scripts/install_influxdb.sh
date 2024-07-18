#!/bin/bash

# Use the specific docker-compose file for influxDB
docker compose -f ~/lpi-monitoring/docker/docker-compose-influxdb.yml up -d
