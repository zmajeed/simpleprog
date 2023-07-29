#!/bin/bash

# wsl_interrupt_stats.sh

# Monitors WSL Hyper-V interrupt counts and prints stats at regular intervals

################################################################################
# MIT License
#
# Copyright (c) 2023 Zartaj Majeed
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
################################################################################

function usage {
  echo "Usage: wsl_interrupt_stats.sh [-h] [-n num_iterations] [-f frequency] [-z timezone]"
  echo "Monitors WSL interrupt counts and prints stats at regular intervals"
  echo "-n: number of iterations, default is 0 for unlimited"
  echo "-f: frequency in seconds, default is 10.0 seconds"
  echo "-z: timezone for logging, default America/Chicago"
  echo "-h: help"
  echo "Examples:"
  echo "wsl_interrupt_stats.sh -n 10 -f 5"
}

function initInterruptStats {
  local epochMicro=$(date +%s.%6N)
  read -a cpus
  numCpus=${#cpus[*]}

  local -a fields
  while read -a fields; do
    local irq=${fields[0]%:}
    irqIds+=($irq)
    irqNames[$irq]=${fields[*]:$numCpus + 1}
# create dynamic arrays per IRQ to hold count:timestamp
    declare -g -a irqCounts_$irq
# can only use dynamic arrays through nameref
    local -n arrayRef=irqCounts_$irq
    arrayRef=(${fields[*]:1:$numCpus})
    arrayRef=(${arrayRef[*]/%/:$epochMicro})
  done
}

function printInterruptStats {
  echo "cpu_count $numCpus"

  local irq
  for irq in ${irqIds[*]}; do
    echo "irq_id $irq irq_name \"${irqNames[$irq]}\""
  done
  echo
  echo "Initial IRQ counts"
  echo "iteration 0 time $(TZ=$timezone date +%F_%T.%6N_%Z)"
  for irq in ${irqIds[*]}; do
    local -n arrayRef=irqCounts_$irq
    echo "irq_id $irq irq_counts ${arrayRef[*]/%:*}"
  done
}

function getInterruptStats {
  local epochMicro=$(date +%s.%N)
  IFS= read

  local -a fields
  while read -a fields; do
    local irq=${fields[0]%:}
    local -a irqCounts=(${fields[*]:1:$numCpus})
# need nameref to access dynamic arrays per IRQ
    local -n arrayRef=irqCounts_$irq
    local i
    for ((i = 0; i < ${#irqCounts[*]}; ++i)); do
      local newCount=${irqCounts[i]}
      local oldCount=${arrayRef[i]%%:*}
      local prevTime=${arrayRef[i]##*:}
      if [[ -z $oldCount ]]; then
        arrayRef[i]=$newCount:$epochMicro
        continue
      fi
      if ((newCount == oldCount)); then
        continue
      fi
      arrayRef[i]=$newCount:$epochMicro
      local change=$((newCount - oldCount))
      local pctChange=$(awk "BEGIN {printf \"%.2f\", $change / $oldCount * 100.}")
      local intervalSeconds=$(awk "BEGIN {printf \"%.6f\", $epochMicro - $prevTime}")
      local ratePerSecond=$(awk "BEGIN {printf \"%.2f\", $change / $intervalSeconds}")
      echo "irq.cpu $irq.$i rate_per_sec $ratePerSecond change $change pct_change $pctChange old_count $oldCount new_count $newCount interval_sec $intervalSeconds"

    done
  done
}

while getopts "f:hn:z:" opt; do
  case $opt in
    f) freqSec=$OPTARG;;
    n) numIters=$OPTARG;;
    z) timezone=$OPTARG;;
    h) usage; exit 0;;

    *) usage; exit 1
  esac
done
shift $((OPTIND-1))

: ${freqSec:=10}
: ${numIters:=0}
: ${timezone:=America/Chicago}

declare -a cpus
declare numCpus=0
declare -a irqIds
declare -A irqNames

# first run
initInterruptStats </proc/interrupts
printInterruptStats
((numIters == 1)) && exit
echo

sleep $freqSec

# keep running
for ((i = 1; numIters == 0 || i < numIters; ++i)); do
  echo "iteration $i time $(TZ=$timezone date +%F_%T.%6N_%Z)"
  getInterruptStats </proc/interrupts
  echo
  sleep $freqSec
done

