#!/bin/bash

# Usage: ./logs.sh <service>
# Available services: iam, patient, testorder

SERVICE_NAME=$1

if [ -z "$SERVICE_NAME" ]; then
  echo "Usage: $0 <service>"
  echo "Available services: iam, patient, testorder"
  exit 1
fi

STACK_NAME="microservices-stack"

case "$SERVICE_NAME" in
  iam)
    SERVICE="${STACK_NAME}_iam-service"
    ;;
  patient)
    SERVICE="${STACK_NAME}_patient-service"
    ;;
  testorder)
    SERVICE="${STACK_NAME}_testorder-service"
    ;;
  *)
    echo "Unknown service: $SERVICE_NAME"
    echo "Available services: iam, patient, testorder"
    exit 1
    ;;
esac

echo "Tailing logs for service: $SERVICE"
