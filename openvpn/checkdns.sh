#!/bin/bash
#Simple script that check if DNS resolution is OK, and stop openvpn client
#simply getting head from a curl command , maybe there is some should be a better way

result=$(/usr/bin/curl -s --head https://www.google.com)
#echo "Result=[$result]"
#exit 1

#Check if  a string $2 is   a substring of another string $1
#Return 1 if $2 is found in $1, 0 if not found
function is_substring
{
my_string=$1
substring=$2
STRFOUND=0
if [ "${my_string/$substring}" = "$my_string" ] ; then
  #echo "DEBUG-[${substring}] is not in [${my_string}]"
  STRFOUND=0
else
  #echo "DEBUG-[${substring}] was found in [${my_string}]"
  STRFOUND=1
fi
 
#echo "DEBUG-STRFOUND=$STRFOUND"
return $STRFOUND
}

#calling substring
is_substring "$result" "HTTP"
dnsresolved=$?
#echo "dnsresolved=[$dnsresolved]"


if [[ "$dnsresolved" == "1" ]]; then
  echo "CheckDNS : google.com successfully resolved...doing nothing"
  exit 0
else
   #killing openvpn
   echo "CheckDNS : unable to resolve DNS google.com ... restarting Openvpn Client"
   pkill --signal SIGKILL "openvpn"
   exit 1
fi