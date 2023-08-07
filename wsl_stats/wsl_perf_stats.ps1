# wsl_perf_stats.ps1

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

param (
$f = 10,
$n = 0,
$t = $true
)

$global:formatenumerationlimit=-1
# disable ansi color escapes in output
if($psversiontable.psversion.major -gt 6) {
  $psstyle.outputrendering = "plaintext"
}

$numIters = $n
$freqSec = $f
$onlyTotals = $t

"numIters $numIters freqSec $freqSec"

$numCpus = [environment]::processorcount

$cpupercent = @{}
$cpupercent2 = @{}
$pids = @{}
$cmdCount = @{}

$numIters = 10

function top {
get-counter -max $numIters "\process(*)\% processor time","\process(*)\id process" -erroraction silentlycontinue | select -expand countersamples | &{ process {
  if($_.instancename -eq "_total") {
    return
  }
  if($_.path.endswith("% processor time") -and $_.cookedvalue -gt 0) {
# path looks like \\myhostname\process(chrome#55)\% processor time
    $_.path -match "\\Process\(([^)]+)\)\\% processor time" >$null
    $cmd = $matches[1]
    $cpupct = [math]::round($_.cookedvalue / $numCpus, 3)

    if($cpupercent.containskey($cmd)) {
      ++$cmdCount[$cmd]
      $cpupercent[$cmd] += $cpupct
    } else {
      $cmdCount[$cmd] = 1
      $cpupercent[$cmd] = $cpupct
    }
  }
  if($_.path.endswith("id process") -and $cpupercent.containskey($_.instancename)) {
    $pids[$_.instancename] = $_.cookedvalue
  }
}}

foreach($cmd in $cpupercent.keys) {
  if(-not $cmd -match "#") {
    continue
  }
  $cmdBase = $cmd -replace "#.*",""
  if($cpupercent2.containskey($cmdBase)) {
    $cpupercent2[$cmdBase] += $cpupercent[$cmd] / $cmdCount[$cmd]
  } else {
    $cpupercent2[$cmdBase] = $cpupercent[$cmd] / $cmdCount[$cmd]
  }
}

foreach($cmd in $cpupercent2.keys) {
  $cmd + " " + [math]::round($cpupercent2[$cmd], 2)
}

get-counter -max 1 "\process(vmmem*)\% processor time" -erroraction silentlycontinue | select -expand countersamples

}

$statsLookup = @{}
$statPatterns = "*hyper-v*" 
#$statPatterns = "*hyper-v*processor*" 
$statId = 0

function printHypervStats {


$hypervStats = get-counter -listset $statPatterns | select -expand paths
$hypervStats | &{ process {
  $listedPathPattern = "^\\(((?<group>[^\\]+)\((?<star>\*)\))|(?<group>[^\\]+))\\(?<name>[^\\]+)$" 
  if(-not ($_ -match $listedPathPattern)) {
    [console]::error.writeline("failed regex match for listed stat path ""$_""") 
    exit 1
	}
  #"stat name ""$($matches.name)"" group ""$($matches.group)"" star ""$($matches.star)"""
  $key = $matches.group + "\" + $matches.name
  $statsLookup[$key] = [pscustomobject]@{
    index = $statId++
    name = $matches.name;
    group = $matches.group;
    sources = if($matches.star -eq "(*)") {"multiple"} else {"unique"};
    lastVals = @{};
  }

}}

				<#
$opts = @{sampleinterval = $using:freqSec}
if($using:numIters -eq 0) {
  $opts.continuous = $true
} else {
  $opts.max = $using:numIters
}
$opts
#>
#get-counter @opts $using:hypervStats -erroraction silentlycontinue | select -expand countersamples | &{ process {

#get-counter -max 1 $using:hypervStats -erroraction silentlycontinue | select -expand countersamples | &{ process {
$statStream = start-threadjob {
  $opts = @{sampleinterval = $using:freqSec}
  if($using:numIters -eq 0) {
    $opts.continuous = $true
  } else {
    $opts.max = $using:numIters
  }
  get-counter $using:hypervStats @opts -erroraction silentlycontinue | select -expand countersamples | &{ process {
    if($using:onlyTotals) {
      if(-not ($_.instancename -in ("_total", ""))) {
				#return
			}
		}
# alternation with shortcircuit hopefully works, first choice matches multisource group with source in parentheses, second choice matches single-source group without any parentheses, first choice allows multisource group itself to have parentheses, second choice assumes unique-source group cannot end in parentheses
    $reportedPathPattern = "^\\\\(?<host>[^\\]+)\\(((?<group>[^\\]+)\((?<source>[^)]+)\))|(?<group>[^\\]+))\\(?<name>[^\\]+)$" 
    if(-not ($_.path -match $reportedPathPattern)) {
      return [pscustomobject]@{
        path = $_.path;
        error = "failed regex match for reported stat path ""$($_.path)"""
      }
		}
    $key = $matches.group + "\" + $matches.name
	  if(-not ($using:statsLookup).containskey($key)) {
      return [pscustomobject]@{
        path = $_.path;
				group = $matches.group
				name = $matches.name
        error = "failed stat lookup for key ""$key"""
      }
	  }
		$source = $_.instancename ?? "unique"
    if(($using:statsLookup)[$key].lastVals[$source] -eq $_.cookedvalue) {
      return
    }
  [pscustomobject]@{
    path = $_.path;
		key = $key;
    name = $matches.name;
    source = $source;
    val = $_.cookedvalue;
    change = $_.cookedvalue - ($using:statsLookup)[$key].lastVals[$source];
    error = $null
	}
  ($using:statsLookup)[$key].lastVals[$source] = $_.cookedvalue
}}

}

receive-job -wait $statStream | &{ process {"got stat ""$_"""}}

}

<#
2023-08-03_10:14:45.572138_CDT: Iteration 0: Initial IRQ counts
cpu_count 4
irq_id 8 irq_counts 0 0 0 0
irq_id 9 irq_counts 192 0 0 0

irq.cpu HVS.0 rate_per_sec 17.87 pct_change 0.00 change 179 old_count 603123807 new_count 603123986

name "timer interrupts/sec" initial_val 45678 group "hyper-v hypervisor logical processor"
name "% total run time" initial_val 391 group "hyper-v hypervisor logical processor"

id 0 name "timer interrupts/sec" rate_per_sec 17.87 pct_change 0.12 change 179 old_val 123807 new_val 23456 sources "lp 1"
name "timer interrupts/sec" rate_per_sec 17.87 pct_change 0.12 change 179 old_val 123807 new_val 23456 sources "sum of lp 1-4"
name "timer interrupts/sec" rate_per_sec 17.87 pct_change 0.12 change 179 old_val 123807 new_val 23456 sources "unique"

$statsByName = @{}
$stat = $statsLookup[$statPath]
$stat.name = $statName
$stat.val = $statVal

function initHypervStats {
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
# can only use dynamic arrays through nameref
    local -n arrayRef=irqCounts_$irq
    arrayRef=(${fields[*]:1:$numCpus})
  done
}
#>

top
printHypervStats

<#
for($iteration = 1; $numIters -eq 0 -or $iteration < $numIters; ++$iteration) {
  sleep $freqSec
  printIterationInfo
  printHypervStats
}
#>
