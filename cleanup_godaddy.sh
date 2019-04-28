#!/bin/bash

# Uncomment this lines only to test this script manually
#CERTBOT_DOMAIN="subdomain.domain.xyz"
#CERTBOT_VALIDATION="test_value"

LOG_DIR="/tmp"
LOG_FILE="$LOG_DIR/cleanup.${CERTBOT_DOMAIN}.log"
SECRET_FILE="/etc/certbot/${CERTBOT_DOMAIN}/secrets"

# Get your API key from https://developer.godaddy.com
API_KEY="your_api_key_here"
API_SECRET="your_api_secret_here"

# Create an empty file if it doesn't exist
if [ -f ${LOG_FILE} ]
then
  touch ${LOG_FILE}
fi

function log {
  DATE=$(date)
  echo "$DATE: $1" >> $LOG_FILE
}

log "[BEGIN]"

# Log SECRET_FILE path to debug
#log "SECRET_FILE $SECRET_FILE"

# Load secrets from an external file
if [ -f ${SECRET_FILE} ]
then
  # Identical to "source ${SECRET_FILE}"
  . ${SECRET_FILE}
  log "SECRET_FILE FOUND : EXTERNAL API KEY USED"
else
  log "SECRET_FILE NOT FOUND : INTERNAL API KEY USED"
fi


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
RECORD_VALUE="none"

if [[ ! -z "${SUBDOMAIN// }" ]]
then
  RECORD_NAME="_acme-challenge.$SUBDOMAIN"
else
  RECORD_NAME="_acme-challenge"
fi

log "RECORD_NAME $RECORD_NAME"

# Update the previous record to default value
RESPONSE_CODE=$(curl -s -X PUT -w %{http_code} \
-H "Authorization: sso-key $API_KEY:$API_SECRET" \
-H "Content-Type: application/json" \
-d "[{\"data\": \"$RECORD_VALUE\", \"ttl\": 600}]" \
"https://api.godaddy.com/v1/domains/$DOMAIN/records/$RECORD_TYPE/$RECORD_NAME")

if [ "$RESPONSE_CODE" == "200" ]
then
  log "OK"
else
  log "KO"
  log $RESPONSE_CODE
fi

log "[END]"
