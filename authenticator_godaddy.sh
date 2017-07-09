#!/bin/bash

# Get your API key from https://developer.godaddy.com
API_KEY="your_api_key_here"
API_SECRET="your_api_secret_here"

# Your domain name like "sample.com", without "www" or/and "http://"
DOMAIN="your_domain_here"

# Strip only the top domain to get the zone id
# DOMAIN=$(expr match "$CERTBOT_DOMAIN" '.*\.\(.*\..*\)')

LOG_DIR="/tmp"
LOG_FILE="$LOG_DIR/authenticator.log"

# Update TXT record
RECORD_TYPE="TXT"
RECORD_NAME="_acme-challenge"
# Uncomment this line only to test this script manually
#CERTBOT_VALIDATION="test_value"
DEFAULT_CERTBOT_VALIDATION="default_value"

echo "[BEGIN]" > $LOG_FILE
echo "CERTBOT VALIDATION $CERTBOT_VALIDATION" >> $LOG_FILE
echo "CERTBOT DOMAIN $CERTBOT_DOMAIN" >> $LOG_FILE

if [ -z $CERTBOT_VALIDATION ]
then
  echo "CERTBOT_VALIDATION is unset" >> $LOG_FILE
  eval CERTBOT_VALIDATION=$DEFAULT_CERTBOT_VALIDATION
  echo "CERTBOT_VALIDATION has been set to $CERTBOT_VALIDATION" >> $LOG_FILE
else
  echo "CERTBOT_VALIDATION is set to '$CERTBOT_VALIDATION'" >> $LOG_FILE
fi


# Update the previous record
JSON_RESPONSE=$(curl -s -X PUT \
-H "Authorization: sso-key $API_KEY:$API_SECRET" \
-H "Content-Type: application/json" \
-d "[{\"data\": \"$CERTBOT_VALIDATION\", \"ttl\": 600}]" \
"https://api.godaddy.com/v1/domains/$DOMAIN/records/$RECORD_TYPE/$RECORD_NAME")

if [ $JSON_RESPONSE == "{}" ]
then
  echo "OK" >> $LOG_FILE
  sleep 25
  TOKEN_FOUND=$(host -t txt _acme-challenge.lambrecht.house | grep $CERTBOT_VALIDATION)
  if [ $? -eq 0 ]
  then
    echo "TOKEN FOUND" >> $LOG_FILE
  else
    echo "TOKEN NOT FOUND" >> $LOG_FILE
  fi
else
  echo "KO" >> $LOG_FILE
  echo $JSON_RESPONSE >> $LOG_FILE
fi

echo "[END]" >> $LOG_FILE
