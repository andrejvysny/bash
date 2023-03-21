#!/bin/bash

function hash_hmac {
  digest="$1"
  data="$2"
  key="$3"
  shift 3
  echo -n "$data" | openssl dgst "-$digest" -hmac "$key" "$@"
}

logFile="logs.txt"
userId="self"
dnsRecordId=$(<"../secrets/WS_DNS_RECORD_ID.txt")
domainName=$(<"../secrets/WS_DOMAIN.txt")
apiKey=$(<"../secrets/WS_API_KEY.txt")
secret=$(<"../secrets/WS_API_SECRET.txt")

myIp=$(dig @resolver4.opendns.com myip.opendns.com +short)
echo -e "updating IP: $myIp"

method="PUT"
api="https://rest.websupport.sk"
path="/v1/user/self/zone/${domainName}/record/${dnsRecordId}"

data='{"content": "'$myIp'"}'

signature=$(hash_hmac "sha1" "${method} ${path} $(date +%s)" "${secret}")

response=$(curl "${api}${path}${query}" -u "${apiKey}:$(echo $signature | cut -d " " -f2)" -H "Date: $(date +%Y%m%dT%H%M%SZ --utc)" -H "Accept: application/json" -H "Content-Type: application/json" -X ${method} -d "${data}")

echo -e "Date: $(date '+%Y-%m-%d %H:%M:%S'); IP: ${myIp}; Response: ${response}" >> logFile