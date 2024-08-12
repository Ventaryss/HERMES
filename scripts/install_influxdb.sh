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
ORG_NAME="lpi"
BUCKET_NAME="logs"
INFLUXDB_USER="admin"
INFLUXDB_PASSWORD="adminadmin"
ADMIN_TOKEN="your_admin_token"  # Ensure this token is set up correctly in InfluxDB

# Create an InfluxDB organization
influx org create -n $ORG_NAME --host http://localhost:8086 -t $ADMIN_TOKEN

# Create an InfluxDB bucket (database)
influx bucket create -n $BUCKET_NAME -o $ORG_NAME --host http://localhost:8086 -t $ADMIN_TOKEN

# Create a read/write token for the bucket
TOKEN=$(influx auth create --org $ORG_NAME --user $INFLUXDB_USER --read-bucket $BUCKET_NAME --write-bucket $BUCKET_NAME --host http://localhost:8086 -t $ADMIN_TOKEN | grep "Token" | awk '{print $2}')

# Store the token in a file for later use
echo $TOKEN > ~/lpi-monitoring/influxdb_token.txt

echo "InfluxDB has been configured."
echo "Organization: $ORG_NAME"
echo "Bucket: $BUCKET_NAME"
echo "Token stored in ~/lpi-monitoring/influxdb_token.txt"
