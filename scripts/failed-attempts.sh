#!/bin/bash
set -e

# Show top failed usernames
echo "Top Failed Usernames:"
echo "===================="
sudo lastb | awk '$1 != "" && $1 != "btmp" {print $1}' | sort | uniq -c | sort -nr | head -10

# Show top failed IPs
echo -e "\nTop Failed IPs:"
echo "==============="
sudo lastb | awk '{print $3}' | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' | sort | uniq -c | sort -nr | head -10
