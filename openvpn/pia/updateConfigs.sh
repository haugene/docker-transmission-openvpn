#!/bin/bash

set -e

# If the script is called from elsewhere
cd "${0%/*}"

# Delete everything (not this script though)
find . ! -name '*.sh' -delete

baseURL="https://www.privateinternetaccess.com/openvpn/openvpn"
extension=".zip"
declare -a configsURLs=(    "" "-strong" "-tcp" "-strong-tcp" "-ip")
declare -a configsFolders=( "" "strong"  "tcp"  "tcp-strong"  "ip")

# warning: keeping folder name "tcp-strong" for legacy reasons, but the url is "strong-tcp".

numberOfConfigTypes=${#configsURLs[@]}

for (( i=1; i<${numberOfConfigTypes}+1; i++ ));
do
  requestURL="$baseURL${configsURLs[$i-1]}$extension"
  if [ ! -z "${configsFolders[$i-1]}" ]
  then
    mkdir -p ${configsFolders[$i-1]} && cd ${configsFolders[$i-1]}
  fi
  curl -kL $requestURL -o openvpn.zip \
    && unzip -j openvpn.zip && rm openvpn.zip

  # Ensure linux line endings
  dos2unix *

  # Update configs with correct paths
  folderNameWithEscapedSlash=""
  if [ ! -z "${configsFolders[$i-1]}" ]
  then
    folderNameWithEscapedSlash="${configsFolders[$i-1]}\/"
  fi
  sed -i "s/auth-user-pass/auth-user-pass \/config\/openvpn-credentials.txt/" *.ovpn
  sed -i "s/ca ca\.rsa\.\([0-9]*\)\.crt/ca \/etc\/openvpn\/pia\/${folderNameWithEscapedSlash}ca\.rsa\.\1\.crt/" *.ovpn
  sed -i "s/crl-verify crl\.rsa\.\([0-9]*\)\.pem/crl-verify \/etc\/openvpn\/pia\/${folderNameWithEscapedSlash}crl\.rsa\.\1\.pem/" *.ovpn
  if [ ! -z "${configsFolders[$i-1]}" ]
  then
    cd ..
  fi
done

# Create symlink for default.ovpn
ln -s "CA Toronto.ovpn" default.ovpn
