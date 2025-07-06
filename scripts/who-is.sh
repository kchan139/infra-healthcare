#!/bin/bash
set -e

# Check if an IP address was provided
if [ -z "$1" ]; then
  echo "Usage: $0 <IP>"
  exit 1
fi

IP="$1"

echo "=== WHOIS for $IP ==="
whois "$IP" | grep -E 'OrgName|OrgId|NetName|CIDR|Country|Name|email|Abuse|descr|Organization' | sort -u
echo

echo "=== Reverse DNS (dig -x) ==="
dig -x "$IP" +short @8.8.8.8
echo

echo "=== IPInfo.io ($IP) ==="
curl -s "https://ipinfo.io/$IP" | jq
