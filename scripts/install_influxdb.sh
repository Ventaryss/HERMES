#!/bin/bash

# Use the specific docker-compose file for InfluxDB
docker compose -f ~/lpi-monitoring/docker/docker-compose-influxdb.yml up -d

# Wait for InfluxDB to start
echo "Waiting for InfluxDB to start..."
sleep 10

# Check if InfluxDB CLI is installed
if ! command -v influx &> /dev/null; then
    echo "InfluxDB CLI not found. Please install it to proceed."
    exit 1
fi

# Define InfluxDB parameters
ORG_NAME="my_org"
BUCKET_NAME="mydb"
INFLUXDB_USER="admin"
INFLUXDB_PASSWORD="password"

# Create an initial admin token if not set
ADMIN_TOKEN=${ADMIN_TOKEN:-$(influx setup --username $INFLUXDB_USER --password $INFLUXDB_PASSWORD --org $ORG_NAME --bucket $BUCKET_NAME --retention 30d --force --json | jq -r '.auth.token')}

# Create an InfluxDB bucket (database) if not exists
if ! influx bucket list -o $ORG_NAME --host http://localhost:8086 -t $ADMIN_TOKEN | grep -q $BUCKET_NAME; then
    influx bucket create -n $BUCKET_NAME -o $ORG_NAME --host http://localhost:8086 -t $ADMIN_TOKEN
fi

# Create a read/write token for the bucket if not exists
TOKEN=$(influx auth list --org $ORG_NAME --user $INFLUXDB_USER --host http://localhost:8086 -t $ADMIN_TOKEN | grep $BUCKET_NAME | awk '{print $4}')

if [ -z "$TOKEN" ]; then
    TOKEN=$(influx auth create --org $ORG_NAME --user $INFLUXDB_USER --read-bucket $BUCKET_NAME --write-bucket $BUCKET_NAME --host http://localhost:8086 -t $ADMIN_TOKEN | grep "Token" | awk '{print $2}')
fi

echo "InfluxDB has been configured."
echo "Bucket: $BUCKET_NAME"
echo "Token: $TOKEN"
