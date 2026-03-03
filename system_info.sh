#!/bin/bash

FILENAME=~/Desktop/dev/system_stats_$(date +%Y-%m-%d_%H-%M-%S).txt

N=${1:-5}

{
    echo "Processor Information:"
    
    echo "Model: $(grep 'model name' /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)"
    
    CORES=$(grep -c '^processor' /proc/cpuinfo)
    echo "Number of Cores: $CORES"
    
    echo ""
    echo "System Interrupts per Core:"
    for ((i=0; i<CORES; i++)); do
        INTERRUPTS=$(awk -v cpu="CPU$i" 'NR==1{for(j=1;j<=NF;j++) if($j==cpu) col=j} NR>1{sum+=$col} END{print sum}' /proc/interrupts)
        echo "Core $i: $INTERRUPTS"
    done
    
    echo ""
    
    declare -A CPU_START
    while IFS= read -r line; do
        if [[ $line =~ ^cpu ]]; then
            name=$(echo $line | awk '{print $1}')
            CPU_START[$name]="$line"
        fi
    done < /proc/stat
    
    sleep $N
    
    declare -A CPU_END
    while IFS= read -r line; do
        if [[ $line =~ ^cpu ]]; then
            name=$(echo $line | awk '{print $1}')
            CPU_END[$name]="$line"
        fi
    done < /proc/stat
    
    echo "Average CPU utilization by all processes for $N seconds:"
    
    read -ra s1 <<< "${CPU_START[cpu]}"
    read -ra s2 <<< "${CPU_END[cpu]}"
    
    idle1=$((s1[4]+s1[5]))
    idle2=$((s2[4]+s2[5]))
    total1=0; for v in "${s1[@]:1}"; do ((total1+=v)); done
    total2=0; for v in "${s2[@]:1}"; do ((total2+=v)); done
    
    dtotal=$((total2-total1))
    didle=$((idle2-idle1))
    
    if [ $dtotal -gt 0 ]; then
        usage=$(awk "BEGIN {printf \"%.2f\", (1 - $didle/$dtotal)*100}")
    else
        usage="0.00"
    fi
    echo "${usage}%"
    
    echo "Average CPU utilization for each core for $N seconds:"
    for ((i=0; i<CORES; i++)); do
        key="cpu$i"
        read -ra s1 <<< "${CPU_START[$key]}"
        read -ra s2 <<< "${CPU_END[$key]}"
        
        idle1=$((s1[4]+s1[5]))
        idle2=$((s2[4]+s2[5]))
        total1=0; for v in "${s1[@]:1}"; do ((total1+=v)); done
        total2=0; for v in "${s2[@]:1}"; do ((total2+=v)); done
        
        dtotal=$((total2-total1))
        didle=$((idle2-idle1))
        
        if [ $dtotal -gt 0 ]; then
            usage=$(awk "BEGIN {printf \"%.2f\", (1 - $didle/$dtotal)*100}")
        else
            usage="0.00"
        fi
        echo "Core $i: ${usage}%"
    done
    
    echo ""
    echo "Memory Information:"
    echo "Total Memory: $(grep MemTotal /proc/meminfo | awk '{print $2, $3}')"
    echo "Free Memory: $(grep MemFree /proc/meminfo | awk '{print $2, $3}')"
    echo "Buffered Memory: $(grep Buffers /proc/meminfo | awk '{print $2, $3}')"
    echo "Cached Memory: $(grep '^Cached' /proc/meminfo | awk '{print $2, $3}')"
    echo "Total Swap Memory: $(grep SwapTotal /proc/meminfo | awk '{print $2, $3}')"
    echo "Available Swap Memory: $(grep SwapFree /proc/meminfo | awk '{print $2, $3}')"

} > "$FILENAME"

echo "Статистику збережено у файл: $FILENAME"
