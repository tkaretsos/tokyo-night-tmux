#!/usr/bin/env bash

ENABLED=$(tmux show-option -gv @tokyo-night-tmux_show_system_monitor 2>/dev/null)
[[ ${ENABLED} -ne 1 ]] && exit 0

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source $CURRENT_DIR/themes.sh

CPU_PREFIX=$(tmux show-option -gv @tokyo-night-tmux_system_monitor_cpu_prefix 2>/dev/null)
RAM_PREFIX=$(tmux show-option -gv @tokyo-night-tmux_system_monitor_ram_prefix 2>/dev/null)
CPU_PREFIX="${CPU_PREFIX:- }"
RAM_PREFIX="${RAM_PREFIX:- }"

read_cpu() {
  awk '/^cpu / {
    idle = $5 + $6
    total = 0
    for (i = 2; i <= NF; i++) total += $i
    print total, idle
  }' /proc/stat
}

read -r t1 i1 < <(read_cpu)
sleep 0.5
read -r t2 i2 < <(read_cpu)

td=$((t2 - t1))
cpu_pct=0
if [[ $td -gt 0 ]]; then
  id=$((i2 - i1))
  cpu_pct=$((100 * (td - id) / td))
fi

mem_total=$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)
mem_available=$(awk '/^MemAvailable:/ {print $2}' /proc/meminfo)
mem_used=$((mem_total - mem_available))
ram_used_gb=$(awk -v k=$mem_used 'BEGIN{printf "%.1f", k/1048576}')
ram_total_gb=$(awk -v k=$mem_total 'BEGIN{printf "%.0f", k/1048576}')

echo "$RESET#[fg=${THEME[foreground]},bg=${THEME[bblack]}] ${CPU_PREFIX}${cpu_pct}% ${RAM_PREFIX}${ram_used_gb}/${ram_total_gb} GB "
