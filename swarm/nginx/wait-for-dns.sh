#!/bin/sh
set -e

echo "[wait-for-dns] Waiting for services dns to resolve..."

for i in $(seq 1 240); do
  if getent hosts tasks.patient-service > /dev/null; then
    echo "[wait-for-dns] DNS resolved!"
    break
  fi
  echo "[wait-for-dns] Still waiting..."
  sleep 1
done

echo "[wait-for-dns] Starting Nginx..."
exec nginx -g 'daemon off;'

