FROM python:3.9-slim

LABEL "com.github.actions.name"="S3 Sync"
LABEL "com.github.actions.description"="Sync a directory to an AWS S3 repository"
LABEL "com.github.actions.icon"="refresh-cw"
LABEL "com.github.actions.color"="green"

LABEL version="0.5.1"
LABEL repository="https://github.com/jakejarvis/s3-sync-action"
LABEL homepage="https://jarv.is/"
LABEL maintainer="Rahul Sharma <rahul.sharma@philips.com>"

# https://github.com/aws/aws-cli/blob/master/CHANGELOG.rst
ENV AWSCLI_VERSION='1.18.14'

# Install necessary packages
RUN pip install boto3 requests

COPY upload_artifactory_to_s3.py /app/

# Install OpenSSL
RUN apk update && \
    apk add --no-cache openssl
    
# Install Curl
RUN apk update && \ 
    apk add --no-cache curl

RUN pip install --quiet --no-cache-dir awscli==${AWSCLI_VERSION}

ADD entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
