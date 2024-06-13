#!/usr/bin/env -S awk -M -E

# format_timer_list.awk

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

# prints /proc/timer_list in table format
#
# cpu_clock  timer                             soft_expire_sec         hard_expire_sec
# ---------  -----                             ---------------         ---------------
# 0:0        0:hrtimer_wakeup                      0.003967617             0.004017617
# 0:0        1:tick_sched_timer                    0.008932734             0.008932734

BEGIN {
  printf "%-9s  %-25s  %22s  %22s\n", "cpu_clock", "timer", "soft_expire_sec", "hard_expire_sec"
  printf "%-9s  %-25s  %22s  %22s\n", "---------", "-----", "---------------", "---------------"
}

/^cpu:/{
  cpu = $2
}

/^ clock / {
  clock = gensub(":", "", 1, $2)
}

/^ #[[:digit:]]+:/ {
  timer_num = gensub("[^[:digit:]]", "", "g", $1)
  timer_name = gensub(",", "", 1, $3)
}

/expires at/ {
  soft = $7/10^9
  hard = $9/10^9
  printf "%-9s  %-25s  %22.9f  %22.9f\n", cpu ":" clock, timer_num ":" timer_name, soft, hard
}
