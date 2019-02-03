#!/bin/bash

# Uncomment this lines only to test this script manually
#CERTBOT_DOMAIN="test_domain"
#CERTBOT_VALIDATION="test_value"

# Get your API key from https://developer.godaddy.com
API_KEY="your_api_key_here"
API_SECRET="your_api_secret_here"

# DNS entry propagation parameters
# Delay between the DNS record update and the first dig request (in seconds)
DELAY_AFTER_DNS_RECORD_UPDATE=30
# Time interval between each dig request (in seconds)
DIG_TIME_INTERVAL=4
# Number of retries of dig request before ending in a failure
DIG_NB_RETRIES=25

# Init variables
DOMAIN=""
SUBDOMAIN=""

LOG_DIR="/tmp"
LOG_FILE="$LOG_DIR/authenticator.$CERTBOT_DOMAIN.log"

echo "" > $LOG_FILE

function log {
  DATE=$(date)
  echo "$DATE: $1" >> $LOG_FILE
}

log "[BEGIN]"

# Detection of root domain or subdomain
if [ "$(uname -s)" == "Darwin" ]
then
  DOMAIN=$(expr "$CERTBOT_DOMAIN" : '.*\.\(.*\..*\)')
  if [[ ! -z "${DOMAIN// }" ]]
  then
    log "SUBDOMAIN DETECTED"
    SUBDOMAIN=$(echo "$CERTBOT_DOMAIN" | awk -F"." '{print $1}')
  else
    DOMAIN=$CERTBOT_DOMAIN
  fi
else
  DOMAIN=$(expr match "$CERTBOT_DOMAIN" '.*\.\(.*\..*\)')
  if [[ ! -z "${DOMAIN// }" ]]
  then
    log "SUBDOMAIN DETECTED"
    SUBDOMAIN=$(echo "$CERTBOT_DOMAIN" | sed "s/.$DOMAIN//")
    DOMAIN=$CERTBOT_DOMAIN
  else
    DOMAIN=$CERTBOT_DOMAIN
  fi
fi

log "DOMAIN $DOMAIN"
log "SUBDOMAIN $SUBDOMAIN"

# Update TXT record
RECORD_TYPE="TXT"

if [[ ! -z "${SUBDOMAIN// }" ]]
then
  RECORD_NAME="_acme-challenge.$SUBDOMAIN"
  NS=$(dig +short $SUBDOMAIN.$DOMAIN ns | tail -1)
else
  RECORD_NAME="_acme-challenge"
  NS=$(dig +short $DOMAIN ns | tail -1)
fi

log "RECORD_NAME $RECORD_NAME"
log "NS $NS"

DEFAULT_CERTBOT_VALIDATION="default_value"

log "CERTBOT VALIDATION $CERTBOT_VALIDATION"
log "CERTBOT DOMAIN $CERTBOT_DOMAIN"

if [ -z $CERTBOT_VALIDATION ]
then
  log "CERTBOT_VALIDATION is unset"
  eval CERTBOT_VALIDATION=$DEFAULT_CERTBOT_VALIDATION
  log "CERTBOT_VALIDATION has been set to $CERTBOT_VALIDATION"
else
  log "CERTBOT_VALIDATION is set to '$CERTBOT_VALIDATION'"
fi


# Update the previous record
IS_NONE=$(dig +short @$NS $RECORD_NAME.$DOMAIN txt | grep -e "none")
if [ $? -eq 0 ]
then
  # Replace the previous record
  RESPONSE_CODE=$(curl -s -X PUT -w %{http_code} \
  -H "Authorization: sso-key $API_KEY:$API_SECRET" \
  -H "Content-Type: application/json" \
  -d "[{\"data\": \"$CERTBOT_VALIDATION\", \"ttl\": 600}]" \
  "https://api.godaddy.com/v1/domains/$DOMAIN/records/$RECORD_TYPE/$RECORD_NAME")
else
  # add to the existing record (for wildcard / SAN certificates)
  RESPONSE_CODE=$(curl -s --request PATCH -w %{http_code} \
  -H "Authorization: sso-key $API_KEY:$API_SECRET" \
  -H "Content-Type: application/json" \
  -d "[{\"data\": \"$CERTBOT_VALIDATION\", \"name\": \"$RECORD_NAME\", \"type\": \"$RECORD_TYPE\", \"ttl\": 600}]" \
  "https://api.godaddy.com/v1/domains/$DOMAIN/records")
fi


if [ "$RESPONSE_CODE" == "200" ]
then
  log "OK"
  sleep $DELAY_AFTER_DNS_RECORD_UPDATE
  I=0
  while [ $I -le $DIG_NB_RETRIES ]
  do
    sleep $DIG_TIME_INTERVAL
    R=$(dig +short @$NS $RECORD_NAME.$DOMAIN txt | grep -e "$CERTBOT_VALIDATION")
    if [ $? -eq 0 ]
    then
      log "TEST $I > TOKEN FOUND"
      break
    else
      log "TEST $I > TOKEN NOT FOUND"
      let I++
    fi
  done
else
  log "KO"
  log $RESPONSE_CODE
fi

log "[END]"
