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

$global:formatenumerationlimit=-1
# disable ansi color escapes in output
if($psversiontable.psversion.major -gt 6) {
  $psstyle.outputrendering = "plaintext"
}

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

function printHypervStats {


$hypervStats = get-counter -listset "*hyper-v*" | select -expand paths

get-counter -max 1 $hypervStats -erroraction silentlycontinue | select -expand countersamples | & { process {
  if($_.instancename -eq "_total") {
  }
  $instanceId = ""
  if($_.cookedvalue -ne 0) {
# path looks like \\myhostname\process(chrome#55)\% processor time
    if($_.path -match "\((?<instanceId>[^)]+)\)\\") {
      $instanceId = $matches.instanceId
      if($instanceId -ne "_total") {return}
    } else {
      $instanceId = "unique"
    }
    $_.path -match "\\(?<statName>[^\\]+)$" >$null
    $statName = $matches.statName
    $statName + "`t" + [math]::round($_.cookedvalue, 3) + "`t" + $instanceId
  }
}}

}

top
printHypervStats
