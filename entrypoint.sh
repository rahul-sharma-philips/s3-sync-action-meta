#!/bin/sh

set -e

# Default to ARTIFACTORY if mode not set.
if [ -z "$MODE" ]; then
  echo "MODE is not set. Quitting." 
fi

#For Artifactory
if [ -z "$ARTIFACTORY_ENDPOINT" ]; then
  echo "ARTIFACTORY_ENDPOINT is not set. Quitting."
  exit 1
fi
if [ -z "$ARTIFACTORY_SECRET" ]; then
  echo "ARTIFACTORY_SECRET is not set. Quitting."
  exit 1
fi
if [ -z "$ARTIFACTORY_USER" ]; then
  echo "ARTIFACTORY_USER is not set. Quitting."
  exit 1
fi
if [ -z "$ARTIFACTORY_RELEASE_PATH" ]; then
  echo "ARTIFACTORY_RELEASE_PATH is not set. Quitting."
  exit 1
fi


if [ "$MODE" = "DOWNLOAD" ] || [ "$MODE" = "DUAL" ]; then
  # Below settings are valid for both modes.
  if [ -z "$AWS_S3_BUCKET" ]; then
    echo "AWS_S3_BUCKET is not set. Quitting."
    exit 1
  fi
  
  if [ -z "$AWS_ACCESS_KEY_ID" ]; then
    echo "AWS_ACCESS_KEY_ID is not set. Quitting."
    exit 1
  fi
  
  if [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    echo "AWS_SECRET_ACCESS_KEY is not set. Quitting."
    exit 1
  fi
  
  # Default to us-east-1 if AWS_REGION not set.
  if [ -z "$AWS_REGION" ]; then
    AWS_REGION="us-east-1"
  fi
  
  # Override default AWS endpoint if user sets AWS_S3_ENDPOINT.
  if [ -n "$AWS_S3_ENDPOINT" ]; then
    ENDPOINT_APPEND="--endpoint-url $AWS_S3_ENDPOINT"
  fi
fi

if [ "$MODE" = "UPLOAD" ] || [ "$MODE" = "DUAL" ]; then
  # Use find to locate all files with the specified extension
  find "$SOURCE_DIR" -type f -name "*.zip" | while read -r file; do
    filename=$(basename "$file")
    curl -u$ARTIFACTORY_USER:$ARTIFACTORY_SECRET -T "$file" "$ARTIFACTORY_ENDPOINT/$ARTIFACTORY_RELEASE_PATH/$filename"
    echo "Uploaded file: $filename to Artifactory endpoint: $ARTIFACTORY_ENDPOINT/$ARTIFACTORY_RELEASE_PATH"  
  done
  if [ "$MODE" = "UPLOAD" ]; then
    exit 0
  fi
fi

# Run the Python script
python3 /app/upload_artifactory_to_s3.py
