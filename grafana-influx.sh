#!/bin/bash

# InfluxDB HTTP-only Installer (Docker already installed)

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root."
    exit 1
fi

read -p "InfluxDB Username: " dbuser
read -sp "InfluxDB Password: " dbpass
echo

dbadminpass="$(tr -dc '[:alpha:]' </dev/urandom | head -c 20)"

docker network create web >/dev/null 2>&1 || true

docker run -d \
  --name InfluxDB \
  --network web \
  -p 8086:8086 \
  --restart unless-stopped \
  -v /root/Docker/Volumes/InfluxDB:/var/lib/influxdb \
  -e INFLUXDB_DB=db01 \
  -e INFLUXDB_HTTP_AUTH_ENABLED=true \
  -e INFLUXDB_USER=$dbuser \
  -e INFLUXDB_USER_PASSWORD=$dbpass \
  -e INFLUXDB_ADMIN_USER=influxadmin \
  -e INFLUXDB_ADMIN_PASSWORD=$dbadminpass \
  -e INFLUXDB_DATA_MAX_VALUES_PER_TAG=0 \
  -e INFLUXDB_DATA_MAX_SERIES_PER_DATABASE=0 \
  influxdb:1.8

sleep 5

docker exec InfluxDB influx \
  -username influxadmin -password $dbadminpass \
  -execute 'ALTER RETENTION POLICY "autogen" ON "db01" DURATION 4w SHARD DURATION 24h'

clear
echo "✅ InfluxDB is running (HTTP only)"
echo
echo "URL: http://<SERVER-IP>:8086"
echo
echo "Rust Server Metrics config:"
cat <<EOF
{
  "Enabled": true,
  "Influx Database Url": "http://<SERVER-IP>:8086",
  "Influx Database Name": "db01",
  "Influx Database User": "$dbuser",
  "Influx Database Password": "$dbpass",
  "Server Tag": "CHANGE-ME"
}
EOF
