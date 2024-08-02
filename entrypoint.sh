#!/bin/sh

set -e

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

# Create a dedicated profile for this action to avoid conflicts
# with past/future actions.
# https://github.com/jakejarvis/s3-sync-action/issues/1
aws configure --profile s3-sync-action <<-EOF > /dev/null 2>&1
${AWS_ACCESS_KEY_ID}
${AWS_SECRET_ACCESS_KEY}
${AWS_REGION}
text
EOF

# Use find to locate all files with the specified extension
find "$SOURCE_DIR" -type f -name "*.zip" | while read -r file; do
    # Process each file here
    hash_value=$(openssl dgst -binary -sha256 "$file" | openssl base64)
    # echo For file: "$file" "SHA-256 hash: $hash_value"
    
    # Extract the filename without path
    filename=$(basename "$file")
    trimmed_path="${file#$SOURCE_DIR/}"

    echo "For trimmed_path: $trimmed_path SHA-256 hash: $hash_value"

    # Upload to S3 with metadata
    aws s3 cp "$file" s3://${AWS_S3_BUCKET}/"$trimmed_path" \
            --metadata '{"HashSHA256":"'$hash_value'"}' 

    echo "Uploaded for trimmed_path: $trimmed_path SHA-256 hash: $hash_value"
    
done

# Clear out credentials after we're done.
# We need to re-run `aws configure` with bogus input instead of
# deleting ~/.aws in case there are other credentials living there.
# https://forums.aws.amazon.com/thread.jspa?threadID=148833
aws configure --profile s3-sync-action <<-EOF > /dev/null 2>&1
null
null
null
text
EOF
