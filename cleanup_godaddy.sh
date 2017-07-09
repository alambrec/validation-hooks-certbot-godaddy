#!/bin/bash

# Get your API key from https://developer.godaddy.com
API_KEY="your_api_key_here"
API_SECRET="your_api_secret_here"

# Your domain name like "sample.com", without "www" or/and "http://"
DOMAIN="your_domain_here"

# Strip only the top domain to get the zone id
# DOMAIN=$(expr match "$CERTBOT_DOMAIN" '.*\.\(.*\..*\)')

LOG_DIR="/tmp"
LOG_FILE="$LOG_DIR/cleanup.log"

# Update TXT record
RECORD_TYPE="TXT"
RECORD_NAME="_acme-challenge"
RECORD_VALUE="none"

echo "[BEGIN]" > $LOG_FILE

# Update the previous record to default value
JSON_RESPONSE=$(curl -s -X PUT \
-H "Authorization: sso-key $API_KEY:$API_SECRET" \
-H "Content-Type: application/json" \
-d "[{\"data\": \"$RECORD_VALUE\", \"ttl\": 600}]" \
"https://api.godaddy.com/v1/domains/$DOMAIN/records/$RECORD_TYPE/$RECORD_NAME")

if [ $JSON_RESPONSE == "{}" ]
then
  echo "OK" >> $LOG_FILE
else
  echo "KO" >> $LOG_FILE
  echo $JSON_RESPONSE >> $LOG_FILE
fi

echo "[END]" >> $LOG_FILE
