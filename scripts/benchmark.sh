#!/bin/bash
set -e

SERVICE=${1:-root}  # Default to 'root' benchmark if no argument is given

echo "Benchmarking service: '$SERVICE'..."

case "$SERVICE" in
  root)
    h2load -n 2500 -c 50 -m 10 https://microservices.khoa.email
    ;;

  iam)
    h2load -n 500 -c 20 -m 10 \
      -H "User-Agent: PostmanRuntime/7.29.0" \
      -H "Content-Type: application/json" \
      -H "Accept: application/json" \
      -d login.json \
      https://microservices.khoa.email/auth/login
    ;;

  patient)
    echo "[placeholder] Would benchmark /api/patient endpoint here"
    ;;

  testorder)
    echo "[placeholder] Would benchmark /api/testorder endpoint here"
    ;;

  *)
    echo "Unknown service: '$SERVICE'"
    echo "Usage: ./benchmark.sh [root|iam|patient|testorder]"
    exit 1
    ;;
esac
