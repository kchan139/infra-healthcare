#!/bin/bash
#
# ufw-port-hit.sh — show top IPs blocked by UFW on specified port(s)
#
# Usage:
#   ./ufw-port-hit.sh 22
#   ./ufw-port-hit.sh 2222 5900 5432

LOGFILE="/var/log/syslog"

if [ $# -lt 1 ]; then
  echo "Usage: $0 <port> [port2 ...] | all"
  exit 1
fi

# ALL mode: show SRC + DPT for every UFW BLOCK
if [ "$1" = "all" ] && [ $# -eq 1 ]; then
  echo "=== UFW Block Summary across ALL ports (SRC → DPT) ==="
  echo
  grep '\[UFW BLOCK\]' "$LOGFILE" \
    | awk '
        /UFW BLOCK/ {
          src=""; dpt="";
          for(i=1;i<=NF;i++){
            if($i ~ /^SRC=/){ split($i,a,"="); src=a[2] }
            if($i ~ /^DPT=/){ split($i,b,"="); dpt=b[2] }
          }
          if(src && dpt) print src, dpt
        }' \
    | sort \
    | uniq -c \
    | sort -nr \
    | awk '{ printf "%4d  %-15s -> %s\n", $1, $2, $3 }'
  exit 0
fi

# Otherwise, build regex "2222|5900|5432" from arguments
PORTS_REGEX=$(printf "|%s" "$@")
PORTS_REGEX=${PORTS_REGEX:1}

echo "=== UFW Block Summary for port(s): $* ==="
echo

grep '\[UFW BLOCK\]' "$LOGFILE" \
  | grep -E "DPT=($PORTS_REGEX)" \
  | awk -F'SRC=' '{print $2}' \
  | awk '{print $1}' \
  | sort \
  | uniq -c \
  | sort -nr \
  | awk '{printf "%4d  %s\n", $1, $2}'
