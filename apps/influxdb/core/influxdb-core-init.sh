#!/usr/bin/env bash
# This script create a database in InfluxDB if it doesn't already exist.

INFLUXDB_HOST="influxdb-core"
INFLUXDB_PORT="80"
INFLUXDB_DATABASE="sensors"

set -euo pipefail

# check whether influxdb has been initialized with admin token, if not generate
# admin token and store it as kubernetes secret
if ! /tmp/kubectl get secret -n "${INFLUXDB_KUBERNETES_NAMESPACE}" influxdb-admin-token
then
  echo "Kubernetes secret influxdb-admin-token doesn't exist, creating it..."

  until timeout 1 bash -c "</dev/tcp/${INFLUXDB_HOST}/${INFLUXDB_PORT}"
  do
    echo "Waiting for InfluxDB to become healthy..."
    sleep 5
  done

  admin_token=$(influxdb3 create token --admin --host "http://${INFLUXDB_HOST}:${INFLUXDB_PORT}" | awk '/^Token: /{print $2}')

  /tmp/kubectl create secret -n "${INFLUXDB_KUBERNETES_NAMESPACE}" generic influxdb-admin-token --from-literal="INFLUXDB3_AUTH_TOKEN=${admin_token}"

  # restart influxdb so health check is proper check via /health which require
  # auth token
  /tmp/kubectl rollout restart -n "${INFLUXDB_KUBERNETES_NAMESPACE}" deploy influxdb-core

  # restart job to get the correct secret
  exit 1
fi

# proper health check, after admin token has been created
until curl -sf -H "Authorization: Bearer $INFLUXDB3_AUTH_TOKEN" "http://${INFLUXDB_HOST}:${INFLUXDB_PORT}/health" >/dev/null
do
  echo "Waiting for InfluxDB to become healthy..."
  sleep 5
done

echo "InfluxDB is healthy, reconciliating configuration..."

if ! influxdb3 show databases --host "http://${INFLUXDB_HOST}:${INFLUXDB_PORT}" | grep -q "$INFLUXDB_DATABASE"; then
  echo "Creating database '$INFLUXDB_DATABASE'..."
  influxdb3 create database "$INFLUXDB_DATABASE" --host "http://${INFLUXDB_HOST}:${INFLUXDB_PORT}"
else
  echo "Database '$INFLUXDB_DATABASE' already exists."
fi
