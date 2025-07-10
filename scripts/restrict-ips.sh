#!/bin/bash
set -e

echo "Locking down port 443 to Cloudflare IPs..."

echo "Fetching Cloudflare IP ranges..."
CLOUDFLARE_IPV4=$(curl -s https://www.cloudflare.com/ips-v4)
CLOUDFLARE_IPV6=$(curl -s https://www.cloudflare.com/ips-v6)

echo "➕ Allowing Cloudflare IPs..."

for ip in $CLOUDFLARE_IPV4; do
    echo "Allowing $ip (IPv4)..."
    ufw allow from $ip to any port 443 proto tcp
done

for ip in $CLOUDFLARE_IPV6; do
    echo "Allowing $ip (IPv6)..."
    ufw allow from $ip to any port 443 proto tcp
done

echo "Done. UFW status:"
ufw status

echo "Port 443 is now only accessible via Cloudflare."
