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

function log {
  local line=$1
  echo "$(TZ=$timezone date +%F_%T.%6N_%Z): $line"
}

function printSystemInfo {
  log "System info"

  log "uname"
  uname -srvmpio
  echo

  log "WSL version info"
  $win32Dir/wsl.exe --version
  echo

}

function initInterruptStats {
  epochMicro=$(date +%s.%6N)
  read -a cpus
  numCpus=${#cpus[*]}

  local -a fields
  while read -a fields; do
    local irq=${fields[0]%:}
    irqIds+=($irq)
    irqNames[$irq]=${fields[*]:$numCpus + 1}
# create dynamic arrays per IRQ to hold counts
    declare -g -a irqCounts_$irq
    declare -g -a irqRates_$irq
# can only use dynamic arrays through nameref
    local -n countsRef=irqCounts_$irq
    countsRef=(${fields[*]:1:$numCpus})

# initialize rate per second array to zeros for same number of entries as in counts array
    local -n ratesRef=irqRates_$irq
    ratesRef=(${countsRef[*]/*/0})
  done
}

function printInterruptCounts {
  log "IRQ info"
  local irq
  printf "%-7s %s\n" irq name
  printf "%-7s %s\n" --- ----
  for irq in ${irqIds[*]}; do
    printf "%-7s" $irq
    printf " %s" ${irqNames[$irq]}
    echo
  done
  echo
  log "Iteration $iteration: Initial IRQ counts"
  echo "cpu_count $numCpus"
  printf "%-7s %s\n" irq counts_by_cpu
  printf "%-7s %s\n" --- -------------
  for irq in ${irqIds[*]}; do
    local -n countsRef=irqCounts_$irq
    printf "%-7s" $irq
    printf " %s" ${countsRef[*]}
    echo
  done
  echo
}

function printInterruptStats {
  log "Iteration $iteration: IRQ diff stats"
  IFS= read

  local outstr=""
  local line
  while IFS= read line; do
    local -a fields=($line)
    local irq=${fields[0]%:}
    local -a irqCounts=(${fields[*]:1:$numCpus})
# need nameref to access dynamic arrays per IRQ
    local -n countsRef=irqCounts_$irq
    local -n ratesRef=irqRates_$irq
    local i
    for ((i = 0; i < ${#irqCounts[*]}; ++i)); do
      local newCount=${irqCounts[i]}
      local oldCount=${countsRef[i]}
      if [[ -z $oldCount ]]; then
        countsRef[i]=$newCount
        continue
      fi
      if ((newCount == oldCount)); then
        ratesRef[i]=0
        continue
      fi
      countsRef[i]=$newCount
      local change=$((newCount - oldCount))

      local ratePerSecond=$(awk "BEGIN {printf \"%.2f\", $change / $intervalSeconds}")

      local oldRate=${ratesRef[i]}
      ratesRef[i]=$ratePerSecond

# percent change in count not useful since counts are cumulative and percentage goes to zero over time
# instead see whether rate went up or down
      local pctChangeInRate=$(awk -v oldRate=$oldRate -v newRate=$ratePerSecond '
        BEGIN {
          if(oldRate == 0) {
            print "Inf"
            exit
          }
					printf "%.2f", (newRate - oldRate) / oldRate * 100.
        }'
      )

      printf -v vals "%-9s  %15s %20s %15s %15s %15s\n" "$irq.$i" $ratePerSecond $pctChangeInRate $change $newCount $oldCount
      outstr+=$vals

    done
  done

  printf "%-9s  %15s %20s %15s %15s %15s\n" irq_cpu rate_per_sec pct_change_in_rate change new_count old_count
  printf "%-9s  %15s %20s %15s %15s %15s\n" ------- ------------ ------------------ ------ --------- ---------
  echo "$outstr" |
  sort -k2,2nr
}

function printTop {
  local numLines=$((numTop + 7))
  log "Iteration $iteration: top"
  top -b -n1 -w120 | head -$numLines
  echo
}

function printIterationInfo {
  log "Iteration $iteration:"
  local -g prevEpochMicro=$epochMicro
  epochMicro=$(date +%s.%6N)
  local -g intervalSeconds=$(awk "BEGIN {printf \"%.6f\", $epochMicro - $prevEpochMicro}")
  echo "interval_sec $intervalSeconds"
  echo
}

while getopts "df:hn:z:" opt; do
  case $opt in
    d) debug=true;;
    f) freqSec=$OPTARG;;
    n) numIters=$OPTARG;;
    z) timezone=$OPTARG;;
    h) usage; exit 0;;

    *) usage; exit 1
  esac
done
shift $((OPTIND-1))

: ${debug:=false}
: ${win32Dir:=/mnt/c/windows/system32}
: ${freqSec:=10}
: ${numIters:=0}
: ${timezone:=America/Chicago}
: ${numTop:=5}

# get UTF-8 output from Windows wsl.exe command
export WSL_UTF8=1
export WSLENV=WSL_UTF8

declare -a cpus
declare numCpus=0
declare -a irqIds
declare -A irqNames

log "Start WSL interrupt stats, frequency_secs $freqSec, num_iterations $numIters"
echo
printSystemInfo

# first run
declare iteration=0
declare epochMicro=$(date +%s.%6N)

initInterruptStats </proc/interrupts
printInterruptCounts
((numIters == 1)) && exit

# keep running
for ((iteration = 1; numIters == 0 || iteration < numIters; ++iteration)); do
  sleep $freqSec
  printIterationInfo
  printInterruptStats </proc/interrupts
  printTop
done

