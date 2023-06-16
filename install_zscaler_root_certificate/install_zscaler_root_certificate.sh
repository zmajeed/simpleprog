#!/bin/bash

# install_zscaler_root_certificate.sh

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

function usage {
  echo "Usage: install_zscaler_root_certificate.sh"
  echo "Run inside WSL distro to install ZScaler root certificate from Windows host"
}

function installCertificate {
  local srcDir=/mnt/c/temp
  local srcPath=$srcDir/$certfileCrt

  local destDir=/usr/local/share/ca-certificates
  local destPath=$destDir/$certfileCrt

  local testUrl=https://download.pytorch.org/models/resnet50-11ad3fa6.pth

  sudo cp -v $srcPath $destPath || return 1
  sudo chmod 644 $destPath || return 1
  ls -l $destPath
  sudo update-ca-certificates || return 1
  echo

  echo "Test curl -I $testUrl"
  if ! curl -I -s $testUrl | grep "200 OK"; then
    rm -v $destPath
    return 1
  fi
}

if (($# > 0)); then
  usage
  exit 1
fi

echo "Install ZScaler root certificate to current distro"
echo "Will prompt for sudo password"

certName="CN=Zscaler Root CA"
certfileBasename=zscaler_root_certificate
tmpdir=c:/temp
tmpdirWSL=${tmpdir/c://mnt/c}

certfileCer=$certfileBasename.cer
certfileCrt=$certfileBasename.crt

certpathCer=$tmpdir/$certfileCer
certpathCrt=$tmpdir/$certfileCrt

certCerPathWSL=$tmpdirWSL/$certfileCer
certCrtPathWSL=$tmpdirWSL/$certfileCrt

finalES=0

powershell.exe "
\"Get ZScaler root certifcate in CER format $certpathCer\"

\$cert = gci cert:/localmachine/root |
        where {\$_.subject -match \"$certName\"}

if(\$cert -eq \$null) {
  [console]::error.writeline(\"No root certificate found with subject matching \`\"$certName\`\"\")
  exit 1
}

export-certificate -cert \$cert -file $certpathCer
''

\"Convert certificate to PEM format $certpathCrt\"
certutil -f -encode $certpathCer $certpathCrt

ls -l $certpathCrt
''
"
finalES=$?

if ((finalES == 0)); then
  echo "Copy PEM file $certpathCrt from Windows and install certificate"
  installCertificate
  finalES=$?
  echo
fi

rm -f $certCerPathWSL
rm -f $certCrtPathWSL

if ((finalES != 0)); then
  echo >&2 "Failed to install ZScaler root certificate"
  exit 2
fi

echo "Successfully installed ZScaler root certificate"
