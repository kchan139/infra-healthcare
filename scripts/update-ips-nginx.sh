#!/bin/bash
set -e

TEMP_CONF="/tmp/nginx_cf_ips.conf"
TARGET_CONF="/etc/nginx/conf.d/cloudflare-ips.conf"

echo "Fetching Cloudflare IP ranges..."
CLOUDFLARE_IPV4=$(curl -s https://www.cloudflare.com/ips-v4)
CLOUDFLARE_IPV6=$(curl -s https://www.cloudflare.com/ips-v6)

echo "Generating nginx geo block..."
cat > "$TEMP_CONF" << 'EOF'
# Auto-generated Cloudflare IP ranges - DO NOT EDIT MANUALLY
geo $is_cloudflare {
    default 0;
EOF

# Add IPv4 ranges
for ip in $CLOUDFLARE_IPV4; do
    echo "    $ip 1;" >> "$TEMP_CONF"
done

# Add IPv6 ranges  
for ip in $CLOUDFLARE_IPV6; do
    echo "    $ip 1;" >> "$TEMP_CONF"
done

echo "}" >> "$TEMP_CONF"

# Move the generated file to nginx conf directory
mv "$TEMP_CONF" "$TARGET_CONF"

# Test nginx config
nginx -t

if [ $? -eq 0 ]; then
    echo "Reloading nginx..."
    systemctl reload nginx
    echo "Cloudflare IPs updated successfully"
else
    echo "Nginx config test failed"
    exit 1
fi
