#!/bin/bash

LOG_DIR="/tmp"
LOG_FILE="$LOG_DIR/authenticator.$CERTBOT_DOMAIN.log"

echo "" > $LOG_FILE

function log {
  DATE=$(date)
  echo "$DATE: $1" >> $LOG_FILE
}

log "[BEGIN]"

# Uncomment this lines only to test this script manually
#CERTBOT_DOMAIN="test_domain"
#CERTBOT_VALIDATION="test_value"

# Get your API key from https://developer.godaddy.com
API_KEY="your_api_key_here"
API_SECRET="your_api_secret_here"

# Init variables
DOMAIN=""
SUBDOMAIN=""

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
else
  RECORD_NAME="_acme-challenge"
fi

log "RECORD_NAME $RECORD_NAME"

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
RESPONSE_CODE=$(curl -s -X PUT -w %{http_code} \
-H "Authorization: sso-key $API_KEY:$API_SECRET" \
-H "Content-Type: application/json" \
-d "[{\"data\": \"$CERTBOT_VALIDATION\", \"ttl\": 600}]" \
"https://api.godaddy.com/v1/domains/$DOMAIN/records/$RECORD_TYPE/$RECORD_NAME")

if [ "$RESPONSE_CODE" == "200" ]
then
  log "OK"
  I=0
  while [ $I -le 5 ]
  do
    sleep 4
    R=$(host -t txt "$RECORD_NAME.$DOMAIN" | grep -e "$CERTBOT_VALIDATION")
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
