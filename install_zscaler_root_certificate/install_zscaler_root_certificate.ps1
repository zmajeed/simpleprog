param([parameter(mandatory, position=0)] $distro)

# installer_zscaler_root_certificate.ps1

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

# Installs ZScaler root certificate from Windows to WSL Ubuntu or Debian distro

$psdefaultparametervalues["*:encoding"] = "utf8"

# prevent major headaches from default wsl UTF-16BE output
$env:WSL_UTF8 = 1

if($distro -notmatch "Ubuntu|Debian") {
  [console]::error.writeline("Sorry! This script only works for Ubuntu or Debian distros")
  exit 1
}

# distro must be up and running for cert install to work
if(! ((wsl --list --verbose) -match "$distro +Running")) {
  [console]::error.writeline("WSL distro $distro is not running. Please start $distro distro to install certificate")
  exit 1
}

"Install ZScaler root certificate to WSL distro $distro"
"Will prompt for sudo password for $distro"
""

$certName = "CN=Zscaler Root CA"
$certfileBasename = "zscaler_root_certificate"
$tmpdir = "c:/temp"
$certfileCer = "$certfileBasename.cer"
$certfileCrt = "$certfileBasename.crt"

$certpathCer = "$tmpdir/$certfileCer"
$certpathCrt = "$tmpdir/$certfileCrt"

"Get ZScaler root certifcate in CER format $certpathCer"

$cert = gci cert:/localmachine/root |
        where {$_.subject -match $certName}

if($cert -eq $null) {
  [console]::error.writeline("No root certificate found with subject matching `"$certName`"")
  exit 1
}

export-certificate -cert $cert -file $certpathCer

"Convert certificate to PEM format $certpathCrt"
certutil -f -encode $certpathCer $certpathCrt

ls -l $certpathCrt
""

"Copy PEM file to WSL distro $distro and install certificate"

$srcDir = "/mnt/c/temp"
$srcPath = "$srcDir/$certfileCrt"

$destDir = "/usr/local/share/ca-certificates"
$destPath = "$destDir/$certfileCrt"

$testUrl = "https://download.pytorch.org/models/resnet50-11ad3fa6.pth"

wsl -d $distro sudo bash -c "
  cp -v $srcPath $destPath || exit 1
  chmod 644 $destPath || exit 1
  ls -l $destPath
  update-ca-certificates || exit 1
  echo

  echo 'Test curl -I $testUrl'
  if ! curl -I -s $testUrl | grep '200 OK'; then
    rm -v $destPath
    exit 1
  fi
"
$wslCmdES = $lastexitcode
""

rm $certpathCer
rm $certpathCrt

if($wslCmdES -ne 0) {
  [console]::error.writeline("Failed to install ZScaler root certificate to WSL distro $distro")
  exit 2
}

"Successfully installed ZScaler root certificate to WSL distro $distro"
