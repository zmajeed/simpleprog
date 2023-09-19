#!/bin/bash

# hvsaction2.sh

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

function log {
  local line=$1
  echo "$(TZ=$timezone date +%F_%T.%6N_%Z): $line"
}

while getopts "z:" opt; do
  case $opt in
    z) timezone=$OPTARG;;
  esac
done
shift $((OPTIND-1))

: ${timezone:=America/Chicago}

iteration=$1

log "Iteration $iteration: hvs_alert_actions: stimer"
cat /sys/kernel/debug/hvtimer/stimer
echo

log "Iteration $iteration: hvs_alert_actions: stimerall"
cat /sys/kernel/debug/hvtimer/stimerall
echo

log "Iteration $iteration: hvs_alert_actions: timesync"
cat /sys/kernel/debug/hvtimer/timesync
echo


