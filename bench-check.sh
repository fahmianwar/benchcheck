#!/bin/bash

# ================= COLOR =================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

JSON_MODE=false
[ "$1" == "--json" ] && JSON_MODE=true

# ================= BASIC INFO =================
HOSTNAME=$(hostname)
DATE=$(date)

if [ -f /etc/os-release ]; then
    OS=$(grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '"')
else
    OS="Unknown"
fi

ARCH=$(uname -m)
KERNEL=$(uname -r)
VIRT=$(systemd-detect-virt 2>/dev/null)
[ -z "$VIRT" ] && VIRT="Unknown"

CPU_MODEL=$(lscpu 2>/dev/null | grep "Model name" | awk -F ':' '{print $2}' | xargs)
CPU_CORES=$(nproc)

AES=$(lscpu | grep -q aes && echo "Enabled" || echo "Disabled")

RAM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
RAM_USED=$(free -m | awk '/Mem:/ {print $3}')
RAM_PERCENT=$((RAM_USED*100/RAM_TOTAL))

SWAP_TOTAL=$(free -m | awk '/Swap:/ {print $2}')
SWAP_USED=$(free -m | awk '/Swap:/ {print $3}')

DISK_TOTAL=$(df -h --total | grep total | awk '{print $2}')
DISK_USED_PERCENT=$(df --total | grep total | awk '{print $5}' | tr -d '%')

LOAD=$(uptime | awk -F'load average:' '{ print $2 }')

TCP_CC=$(sysctl net.ipv4.tcp_congestion_control 2>/dev/null | awk '{print $3}')
[ -z "$TCP_CC" ] && TCP_CC="Unknown"

IPV4=$(ip -4 addr show scope global 2>/dev/null | grep inet | awk '{print $2}' | cut -d/ -f1 | head -n1)
IPV6=$(ip -6 addr show scope global 2>/dev/null | grep inet6 | awk '{print $2}' | cut -d/ -f1 | head -n1)

# ================= HEALTH SCORE =================
SCORE=100

[ $RAM_PERCENT -gt 80 ] && SCORE=$((SCORE-20))
[ $RAM_PERCENT -gt 60 ] && SCORE=$((SCORE-10))
[ $DISK_USED_PERCENT -gt 80 ] && SCORE=$((SCORE-15))
[ $CPU_CORES -lt 2 ] && SCORE=$((SCORE-10))
[ "$SWAP_TOTAL" -eq 0 ] && SCORE=$((SCORE-5))

# ================= ROLE SUGGESTION =================
ROLE="General Purpose"

if [ $RAM_TOTAL -ge 8000 ] && [ $CPU_CORES -ge 4 ]; then
    ROLE="Database Node"
elif [ $RAM_TOTAL -ge 4000 ]; then
    ROLE="App Node"
elif [ $DISK_USED_PERCENT -lt 70 ]; then
    ROLE="Storage Node"
else
    ROLE="Light App / Testing Only"
fi

# ================= JSON OUTPUT =================
if $JSON_MODE; then
cat <<EOF
{
  "hostname": "$HOSTNAME",
  "os": "$OS",
  "kernel": "$KERNEL",
  "arch": "$ARCH",
  "virtualization": "$VIRT",
  "cpu_model": "$CPU_MODEL",
  "cpu_cores": "$CPU_CORES",
  "ram_total_mb": "$RAM_TOTAL",
  "ram_used_mb": "$RAM_USED",
  "swap_total_mb": "$SWAP_TOTAL",
  "disk_total": "$DISK_TOTAL",
  "ipv4": "${IPV4:-null}",
  "ipv6": "${IPV6:-null}",
  "health_score": "$SCORE",
  "suggested_role": "$ROLE"
}
EOF
exit 0
fi

# ================= COLOR STATUS =================
[ -z "$IPV4" ] && IPV4="${RED}Not detected${NC}" || IPV4="${GREEN}$IPV4${NC}"
[ -z "$IPV6" ] && IPV6="${RED}Not detected${NC}" || IPV6="${GREEN}$IPV6${NC}"

if [ $RAM_PERCENT -gt 80 ]; then RAM_COLOR=$RED
elif [ $RAM_PERCENT -gt 60 ]; then RAM_COLOR=$YELLOW
else RAM_COLOR=$GREEN
fi

if [ $SCORE -ge 80 ]; then SCORE_COLOR=$GREEN
elif [ $SCORE -ge 60 ]; then SCORE_COLOR=$YELLOW
else SCORE_COLOR=$RED
fi

# ================= OUTPUT =================
echo -e "${BLUE}================ Cluster Smart Bench ================${NC}"
echo " Hostname           : $HOSTNAME"
echo " Date               : $DATE"
echo " OS                 : $OS"
echo " Kernel             : $KERNEL"
echo " Arch               : $ARCH"
echo " Virtualization     : $VIRT"
echo "----------------------------------------------------"
echo " CPU Model          : $CPU_MODEL"
echo " CPU Cores          : $CPU_CORES"
echo " AES-NI             : $AES"
echo "----------------------------------------------------"
echo -e " RAM Usage          : ${RAM_COLOR}${RAM_TOTAL}MB (${RAM_PERCENT}%)${NC}"
echo " Swap               : ${SWAP_TOTAL}MB (Used ${SWAP_USED}MB)"
echo " Disk Total         : $DISK_TOTAL"
echo " Disk Used          : ${DISK_USED_PERCENT}%"
echo " Load Average       : $LOAD"
echo " TCP CC             : $TCP_CC"
echo "----------------------------------------------------"
echo -e " IPv4               : $IPV4"
echo -e " IPv6               : $IPV6"
echo "----------------------------------------------------"
echo -e " Health Score       : ${SCORE_COLOR}$SCORE/100${NC}"
echo -e " Suggested Role     : ${YELLOW}$ROLE${NC}"
echo -e "${BLUE}=====================================================${NC}"
