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


if [ "$MODE" = "DOWNLOAD" ]; then
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

if [ "$MODE" = "UPLOAD" ]; then
  # Use find to locate all files with the specified extension
  find "$SOURCE_DIR" -type f -name "*.zip" | while read -r file; do
    curl -u$ARTIFACTORY_USER:$ARTIFACTORY_SECRET -T "$file" "$ARTIFACTORY_ENDPOINT/$ARTIFACTORY_RELEASE_PATH"
    filename=$(basename "$file")
    echo "Uploaded file: $filename to Artifactory endpoint: $ARTIFACTORY_ENDPOINT/$ARTIFACTORY_RELEASE_PATH"  
  done
fi

# Create a dedicated profile for this action to avoid conflicts
# with past/future actions.
# https://github.com/jakejarvis/s3-sync-action/issues/1
#aws configure --profile s3-sync-action <<-EOF > /dev/null 2>&1
#${AWS_ACCESS_KEY_ID}
#${AWS_SECRET_ACCESS_KEY}
#${AWS_REGION}
#text
#EOF
  
#if [ "$MODE" = "DOWNLOAD" ]; then


  #curl -u $ARTIFACTORY_USER:ARTIFACTORY_SECRET "$ARTIFACTORY_ENDPOINT/$ARTIFACTORY_RELEASE_PATH" | \
  #aws s3 cp -  s3://$AWS_S3_BUCKET/$ARTIFACTORY_RELEASE_PATH --region $AWS_REGION


  # Clear out credentials after we're done.
  # We need to re-run `aws configure` with bogus input instead of
  # deleting ~/.aws in case there are other credentials living there.
  # https://forums.aws.amazon.com/thread.jspa?threadID=148833
  #aws configure --profile s3-sync-action <<-EOF > /dev/null 2>&1
#fi

#null
#null
#null
#text
#EOF
