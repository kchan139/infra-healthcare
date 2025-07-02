#!/bin/bash

set -e

SCRIPT_DIR="$(dirname "$0")"

source "$SCRIPT_DIR"/../.env

DIGITALOCEAN_TOKEN=$DIGITALOCEAN_TOKEN terraform destroy
