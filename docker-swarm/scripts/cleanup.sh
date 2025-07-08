#!/bin/bash

# Get all active stack names
STACKS=$(docker stack ls --format '{{.Name}}')

if [ -z "$STACKS" ]; then
  echo "No stacks to remove."
  exit 0
fi

echo "The following Docker stacks will be removed:"
echo "$STACKS"
echo

read -p "Are you sure you want to remove all these stacks? (y/N): " CONFIRM

if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo "Removing stacks..."
  for STACK in $STACKS; do
    echo "Removing $STACK..."
    docker stack rm "$STACK"
  done
  echo "Waiting for services to stop..."
  sleep 5
  echo "Done."
else
  echo "Aborted."
  exit 1
fi
