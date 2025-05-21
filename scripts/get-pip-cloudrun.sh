#!/bin/bash

# Enable strict error handling
set -euo pipefail

# Check if the environment arguments is provided
if [ $# -lt 1 ]; then
  echo "[ERROR] Environment name is required as an argument (e.g., dev, prod)"
  echo "Usage: $0 <environment>"
  exit 1
fi

# Variariable
ENV="$1"                                    # Enviroment name
SERVICE_NAME="php-app-$ENV"                # service name
REGION="${REGION:-europe-west1}"            # Region can be overwrite

LOG_FILE="cloud_run_ip_${ENV}.log"         # Log file

# Start Logging
echo "Starting Cloud Run IP retrieval script" | tee -a "$LOG_FILE"
echo "Environment: $ENV" | tee -a "$LOG_FILE"
echo "Region: $REGION" | tee -a "$LOG_FILE"
echo "service: $SERVICE_NAME" | tee -a "$LOG_FILE"

# Check if gcloud CLI is installed
if ! command -v gcloud &> /dev/null; then
  echo "gcloud CLI not found. Please install it and run 'gcloud auth login'" | tee -a "$LOG_FILE"
  exit 2
fi

# Retrieving the service URL from Cloud Run
echo "Fetching service URL from Cloud Run..." | tee -a "$LOG_FILE"

SERVICE_URL=$(gcloud run services describe "$SERVICE_NAME" \
  --platform=managed \
  --region="$REGION" \
  --format='value(status.url)' 2>>"$LOG_FILE")

if [ -z "$SERVICE_URL" ]; then
  echo "Fail to retrieve service URL for $SERVICE_NAME" | tee -a "$LOG_FILE"
  exit 3
fi

echo "Service URL: $SERVICE_URL" | tee -a "$LOG_FILE"

# Resolve IP address from URL
echo "Resolving ip qddress from service URL..." | tee -a "$LOG_FILE"

# Etract domain from URL
DOMAIN=$(echo "$SERVICE_URL" | awk -F/ '{print $3}')
IP_ADDRESS=$(dig +short "$DOMAIN" | tail -n1)

if [ -z "$IP_ADDRESS" ]; then
  echo "Unabl to resolve public IP from domain: $DOMAIN" | tee -a "$LOG_FILE"
  echo "Service URL: $SERVICE_URL (IP not resolved)" | tee -a "$LOG_FILE"
else
  echo "Public IP address for $SERVICE_NAME: $IP_ADDRESS" | tee -a "$LOG_FILE"
fi

# End of script
echo "Script completed." | tee -a "$LOG_FILE"
