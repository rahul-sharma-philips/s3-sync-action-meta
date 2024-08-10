import os
import requests
import boto3
from botocore.exceptions import NoCredentialsError

# Artifactory and AWS credentials
ARTIFACTORY_URL = os.getenv('ARTIFACTORY_ENDPOINT')  # e.g., "https://artifactory.example.com/artifactory"
ARTIFACTORY_REPO = os.getenv('ARTIFACTORY_RELEASE_PATH')  # e.g., "my-repo"
ARTIFACTORY_USERNAME = os.getenv('ARTIFACTORY_USER')
ARTIFACTORY_PASSWORD = os.getenv('ARTIFACTORY_SECRET')

AWS_ACCESS_KEY_ID = os.getenv('AWS_ACCESS_KEY_ID')
AWS_SECRET_ACCESS_KEY = os.getenv('AWS_SECRET_ACCESS_KEY')
AWS_S3_BUCKET = os.getenv('AWS_S3_BUCKET')

# Create a session with AWS
s3_client = boto3.client(
    's3',
    aws_access_key_id=AWS_ACCESS_KEY_ID,
    aws_secret_access_key=AWS_SECRET_ACCESS_KEY
)

def get_artifactory_files(repo_url):
    # Get the list of files from Artifactory
    response = requests.get(repo_url, auth=(ARTIFACTORY_USERNAME, ARTIFACTORY_PASSWORD))
    response.raise_for_status()
    files = response.json()
    return [file['uri'] for file in files['files']]

def upload_file_to_s3(file_url, s3_bucket, s3_key):
    # Stream file from Artifactory and upload to S3
    with requests.get(file_url, auth=(ARTIFACTORY_USERNAME, ARTIFACTORY_PASSWORD), stream=True) as response:
        response.raise_for_status()
        try:
            s3_client.upload_fileobj(response.raw, s3_bucket, s3_key)
            print(f"Successfully uploaded {s3_key} to S3")
        except NoCredentialsError:
            print("Credentials not available")

def main():
    repo_url = f"{ARTIFACTORY_URL}/{ARTIFACTORY_REPO}/"
    files = get_artifactory_files(repo_url)

    for file_uri in files:
        file_url = f"{repo_url}{file_uri}"
        s3_key = file_uri.lstrip('/')  # Adjust as necessary for your S3 structure
        upload_file_to_s3(file_url, AWS_S3_BUCKET, s3_key)

if __name__ == "__main__":
    main()
