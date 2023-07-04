#!/bin/bash

# HTTP endpoint URL
ENDPOINT_URL="https://r7ah3110fl.execute-api.eu-central-1.amazonaws.com/v1/events"

# Generate random data
random_data=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

# Prepare JSON payload
payload="{\"data\": \"$random_data\"}"


count=100
for i in $(seq $count); do
    curl -X POST \
  -H "Content-Type: application/json" \
  -d "$payload" \
  "$ENDPOINT_URL"
done