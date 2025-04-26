#!/usr/bin/env bash

INFLUXDB_HOST=http://influxdb-core
INFLUXDB_DATABASE=default

set -e

until curl -sf -H "Authorization: Bearer $INFLUXDB3_AUTH_TOKEN" "${INFLUXDB_HOST}/health" >/dev/null
do
  echo "Waiting for InfluxDB to become healthy..."
  sleep 5
done

echo "InfluxDB is health, reconciliating configuration..."

if ! influxdb3 show databases --host "$INFLUXDB_HOST" --token "$INFLUXDB3_AUTH_TOKEN" | grep -q "$INFLUXDB_DATABASE"; then
  echo "Creating database '$INFLUXDB_DATABASE'..."
  influxdb3 create database "$INFLUXDB_DATABASE" --host "$INFLUXDB_HOST" --token "$INFLUXDB3_AUTH_TOKEN"
else
  echo "Database '$INFLUXDB_DATABASE' already exists."
fi
