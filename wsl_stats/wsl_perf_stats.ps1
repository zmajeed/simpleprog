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

#requires -version 6

using namespace system.collections.generic

param (
$f = 10,
$n = 0,
$t = $true
)

$global:formatenumerationlimit=-1
# disable ansi color escapes in output
$psstyle.outputrendering = "plaintext"

$numIters = $n
$freqSec = $f
$onlyTotals = $t

"numIters $numIters freqSec $freqSec"

$numCpus = [environment]::processorcount
"cpus $numCpus"

$cpupercent = @{}
$cpupercent2 = @{}
$pids = @{}
$cmdCount = @{}

new-variable timestamp -option allscope

function top {

  get-counter -max 10 "\process(*)\% processor time","\process(*)\id process" -erroraction silentlycontinue | select -expand countersamples | &{ process {
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

<#
foreach($cmd in $cpupercent2.keys) {
  $cmd + " " + [math]::round($cpupercent2[$cmd], 2)
}
#>

$cpupercent3 = [list[pscustomobject]]@()
$cpupercent2.getenumerator() | &{ process { $cpupercent3.add([pscustomobject]@{cmd = $_.key; pct_cpu = $_.value}) }}

$cpupercent3 |
sort pct_cpu -descending

#get-counter -max 3 "\process(vmmem*)\% processor time" -erroraction silentlycontinue | select -expand countersamples | fl *

}


$statsLookup = @{}
set-variable statsLookup -option allscope
$statPatterns = "*hyper-v*" 
$statId = 0

function getStatNames {

get-counter -listset $statPatterns |
select -expand paths |
&{ process {

# stat paths look like
# \Hyper-V Hypervisor\Logical Processors
# \Hyper-V Hypervisor Logical Processor(*)\Total Interrupts/sec
# \Hyper-V Virtual IDE Controller (Emulated)(*)\Write Bytes/sec
# path has group segment and name segment separated by backslash
# star in parentheses (*) at end of group segment means the stat is reported by multiple sources
  $listedPathPattern = "^\\(((?<group>[^\\]+)\((?<star>\*)\))|(?<group>[^\\]+))\\(?<name>[^\\]+)$" 
  if(-not ($_ -match $listedPathPattern)) {
    [console]::error.writeline("failed regex match for listed stat path ""$_""") 
    exit 1
  }
  $key = $matches.group + "\" + $matches.name
  $statsLookup[$key] = [pscustomobject]@{
    index = $statId++
    name = $matches.name
    group = $matches.group
    source = if($matches.star -ne $null) {"multiple"} else {"unique"}
    lastVals = @{}
    path = $_
  }

}}

}

function printStatNames {
  $statsLookup.getenumerator() |
  sort {$_.value.index} |
  select -expand value |
  &{ process { "index " + $_.index + " stat """ + $_.name + """ group """ + $_.group + """ source " + $_.source }}

}

function lookupReportedStatPath {
  param (
    $valuefrompipeline = $true
  )

  process {
# choice order in alternation hopefully works because both match length of both choices are equal, first choice matches multisource group with source in parentheses, second choice matches single-source group without any parentheses, first choice allows multisource group itself to have parentheses, second choice assumes unique-source group cannot end in parentheses
    $reportedPathPattern = "^\\\\(?<host>[^\\]+)\\(((?<group>[^\\]+)\((?<source>[^)]+)\))|(?<group>[^\\]+))\\(?<name>[^\\]+)$" 
    if(-not ($_.path -match $reportedPathPattern)) {
      return [pscustomobject]@{
        path = $_.path
        error = "failed regex match for reported stat path ""$($_.path)"""
      }
    }
    $key = $matches.group + "\" + $matches.name
    if(-not $statsLookup.containskey($key)) {
      return [pscustomobject]@{
        path = $_.path
        group = $matches.group
        name = $matches.name
        error = "failed stat lookup for key ""$key"""
      }
    }
    $source = $_.instancename ?? "unique"
    [pscustomobject]@{
      key = $key
      source = $source
      val = $_.cookedvalue
    }
  }
}

function printInitialStats {

  $allStats = [list[string]]@()
  $statsLookup.getenumerator() | % {$allStats.add($_.value.path)}

  get-counter $allStats -erroraction silentlycontinue |
  &{ process {$timestamp = $_.timestamp; $_}} |
  select -expand countersamples |
  lookupReportedStatPath |
  ? {$_.source -in ("_total", "unique")} |
  &{ process {
    $stat = $statsLookup[$_.key]
    $stat.lastVals[$_.source] = $_.val
   "" + $_.val + "`t" + $stat.name + "`t" + $_.source + "`t" + $stat.group
  }}

}

function getStatUpdates {

  $allStats = [list[string]]@()
  $statsLookup.getenumerator() | % {$allStats.add($_.value.path)}

  $iteration = 1

  get-counter $allStats -max 4 -erroraction silentlycontinue |
  &{ process {
    $intervalSeconds = ($_.timestamp - $timestamp).totalseconds
    $timestamp = $_.timestamp

    write-information -informationaction continue ""
    write-information -informationaction continue "Iteration $iteration"
    write-information -informationaction continue "time $($_.timestamp.tostring("yyyy-MM-dd_HH:mm:ss.ffffffK")) interval_sec $intervalSeconds"
    write-information -informationaction continue ""
    ++$iteration
    $_.countersamples |
    lookupReportedStatPath |
    ? {$_.source -in ("_total", "unique")} |
    &{ process {
      $stat = $statsLookup[$_.key]
      $lastVal = $stat.lastVals[$_.source]
      if($_.val -eq $lastVal) {
        return
      }
      $change = $_.val - $lastVal
      $pctChange = if($lastVal -ne 0) { $change / $lastVal * 100 } else {"Inf" }
      $ratePerSec = $change / $intervalSeconds
      [pscustomobject]@{
        name = $stat.name
        rate_per_sec = $ratePerSec
        pct_change = $pctChange
        change = $change
        new_value = $_.val
        old_value = $lastVal
        source = $_.source
        group = $stat.group
      }
      $stat.lastVals[$_.source] = $_.val
    }} |
    sort rate_per_sec -descending |
    ft -auto
  }}

}

top
""

getStatNames

"Stat names"
printStatNames
""

"Initial stats"
printInitialStats
""

"Incremental changes"
getStatUpdates
""

