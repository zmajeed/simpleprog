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
# disable select-object ansi color escapes
if($psversiontable.psversion.major -gt 6) {
  $psstyle.outputrendering = "plaintext"
}

$numCpus = [environment]::processorcount

#get-counter -listset "*processor*" | select countersetname -expand paths | select countersetname,@{n="path";e={$_}}
#get-counter -listset "*processor*" | % {$_.countersetname; $_ | select -expand paths}
#get-counter -listset "process" | % {$_.countersetname; $_ | select -expand paths}
#get-counter -listset "*hyper*" | % {$_.countersetname; $_ | select -expand paths}
#exit

#get-counter -continuous "\process(*)\% processor time" -erroraction silentlycontinue | select -expand countersamples | ? {$_.status -eq 0 -and $_.cookedvalue -gt 0} | select instancename,cookedvalue
#get-counter -max 2 "\process(*)\id process","\process(*)\% processor time" -erroraction silentlycontinue | select -expand countersamples | ? {$_.status -eq 0 -and $_.cookedvalue -gt 0} | % {$_.instancename + " " + $_.cookedvalue}
#get-counter -max 2 "\process(*)\id process","\process(*)\% processor time" -erroraction silentlycontinue | select -expand countersamples | fl *
#get-counter -max 1 "\process(*)\% processor time","\process(*)\id process" -erroraction silentlycontinue | select countersamples | fl *
#get-counter -max 1 "\process(*)\% processor time","\process(*)\id process" -erroraction silentlycontinue | select -expand readings | % {"reading: """ + $_ + """"}
#get-counter -max 1 "\process(*)\% processor time","\process(*)\id process" -erroraction silentlycontinue | select {$_.readings -split "`n`n" -replace " :`n",": "}
#get-counter -max 1 "\process(*)\% processor time","\process(*)\id process" -erroraction silentlycontinue | get-member | fl *
#get-counter -max 2 "\process(*)\id process","\process(*)\% processor time" -erroraction silentlycontinue

$cpupercent = @{}
$cpupercent2 = @{}
$pids = @{}
$cmdCount = @{}

$numIters = 10

if($false) {
get-counter -max 3 "\process(*)\% processor time","\process(*)\id process" -erroraction silentlycontinue | select -expand countersamples | ? {
  if($_.instancename -eq "_total") {
    return $false
  }
  if($_.path.endswith("% processor time") -and $_.cookedvalue -gt 0) {
    $cpupercent[$_.instancename] = $_.cookedvalue
    return $true
  }
  if($_.path.endswith("id process") -and $cpupercent.containskey($_.instancename)) {
    $pids[$_.instancename] = $_.cookedvalue
    return $true
  }
  return $false
}

} elseif($true) {
get-counter -max $numIters "\process(*)\% processor time","\process(*)\id process" -erroraction silentlycontinue | select -expand countersamples | &{ process {
  if($_.instancename -eq "_total") {
    return
  }
  if($_.path.endswith("% processor time") -and $_.cookedvalue -gt 0) {
# path looks like \\myhostname\process(chrome#55)\% processor time
    $_.path -match "\\Process\(([^)]+)\)\\% processor time" >$null
    $cmd = $matches[1]
    $cpupct = [math]::round($_.cookedvalue / $numCpus, 3)

#"cmd $cmd cpu $cpupct"

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

} elseif($false) {
get-counter -max 3 "\process(*)\% processor time","\process(*)\id process" -erroraction silentlycontinue | select -expand countersamples | fl *

} else {

$stats = get-counter -max 3 "\process(*)\% processor time","\process(*)\id process" -erroraction silentlycontinue | select -expand countersamples

foreach($stat in $stats) {
  if($stat.instancename -eq "_total") {
    continue
  }
  if($stat.path.endswith("% processor time") -and $stat.cookedvalue -gt 0) {
    $cpupercent[$stat.instancename] = $stat.cookedvalue / 100. / $numCpus
    continue
  }
  if($stat.path.endswith("id process") -and $cpupercent.containskey($stat.instancename)) {
    $pids[$stat.instancename] = $stat.cookedvalue
  }
}
}

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
  #$cpupercent.remove($cmd)
}

foreach($cmd in $cpupercent2.keys) {
  #$cmd + " " + $pids[$cmd] + " " + $cpupercent[$cmd]
  $cmd + " " + [math]::round($cpupercent2[$cmd], 2)
}

get-counter -max 1 "\process(vmmem*)\% processor time" -erroraction silentlycontinue | select -expand countersamples

#get-counter -max 1 "\hyper-v hypervisor virtual processor(*)\hardware interrupts/sec" -erroraction silentlycontinue | select -expand countersamples

$hypervStats = get-counter -listset "*hyper-v*" | select -expand paths

#$hypervStats | fl *

#get-counter -max 1 "\hyper-v hypervisor virtual processor(*)\*interrupt*" -erroraction silentlycontinue | select -expand countersamples | & { process {

get-counter -max 1 $hypervStats -erroraction silentlycontinue | select -expand countersamples | & { process {
  if($_.instancename -eq "_total") {
    #return
  }
  $instanceId = ""
  if($_.cookedvalue -ne 0) {
# path looks like \\myhostname\process(chrome#55)\% processor time
    if($_.path -match "\((?<instanceId>[^)]+)\)\\") {
      $instanceId = $matches.instanceId
			#"instanceId regex match $instanceId"
		  if($instanceId -ne "_total") {return}
		} else {
      $instanceId = "unique"
			#"no regex match path ""$($_.path)"""
		}
    $_.path -match "\\(?<statName>[^\\]+)$" >$null
    $statName = $matches.statName
    #"""$($_.path)""" + " " + """$statName""" + " " + """$($_.instancename)""" + " " + [math]::round($_.cookedvalue, 2)
    #$statName + "`t" + [math]::round($_.cookedvalue, 2) + $(if($_.instancename -ne "") {"`t" + $_.instancename} else {"unique"})
    $statName + "`t" + [math]::round($_.cookedvalue, 3) + "`t" + $instanceId
	}
}}

#$hypervCounters = [
#"Interrupts Sent/sec",
#"Interrupts Received/sec",
#]

#get-counter -max 3 "" -erroraction silentlycontinue | select -expand countersamples
