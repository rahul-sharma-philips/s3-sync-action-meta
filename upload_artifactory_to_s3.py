import os
import requests
import boto3
import hashlib
from bs4 import BeautifulSoup

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
    print("repo_url",repo_url)
    print("ARTIFACTORY_USERNAME",ARTIFACTORY_USERNAME)
    headers = {
        "X-JFrog-Art-Api": ARTIFACTORY_PASSWORD  # API key header
    }
    try:
        response = requests.get(repo_url, headers=headers)
        response.raise_for_status()
        # Check that the content type is application/json
        content_type = response.headers.get('Content-Type', '')
        if 'application/json' in content_type:
            try:
                files = response.json()
                return [file['uri'] for file in files['files']]
            except requests.exceptions.JSONDecodeError:
                print(f"Error: The response from Artifactory is not in JSON format. Response content: {response.text}")
                return []
        else:
            zip_files = []
            soup = BeautifulSoup(response.text, 'html.parser')
            for link in soup.find_all('a'):
                href = link.get('href')
                if href.endswith('.zip'):
                    zip_files.append(href)
            return zip_files
    except requests.exceptions.RequestException as e:
        print(f"Error: Failed to retrieve files from Artifactory. {e}")
        return []

class StreamWrapper:
    def __init__(self, generator):
        self.generator = generator
        self.leftover = b""

    def read(self, size=-1):
        if size == -1:
            size = 1024 * 1024  # 1MB default read size

        chunks = []
        remaining_size = size

        # Use leftover data if any
        if self.leftover:
            chunks.append(self.leftover)
            remaining_size -= len(self.leftover)
            self.leftover = b""

        try:
            while remaining_size > 0:
                chunk = next(self.generator)
                if len(chunk) > remaining_size:
                    chunks.append(chunk[:remaining_size])
                    self.leftover = chunk[remaining_size:]
                    break
                chunks.append(chunk)
                remaining_size -= len(chunk)

        except StopIteration:
            pass

        return b"".join(chunks)

def upload_file_to_s3(file_url, s3_bucket, s3_key):
    # Stream file from Artifactory and upload to S3
    with requests.get(file_url, auth=(ARTIFACTORY_USERNAME, ARTIFACTORY_PASSWORD), stream=True) as response:
        response.raise_for_status()
        
        # Initialize the hash object
        sha256_hash = hashlib.sha256()
        # Define a generator to stream the data and update the hash
        def file_stream():
            for chunk in response.iter_content(chunk_size=8192):
                if chunk:  # filter out keep-alive new chunks
                    sha256_hash.update(chunk)
                    yield chunk
        
        # Use the custom stream wrapper
        stream_wrapper = StreamWrapper(file_stream())
        
        # Upload to S3 with computed SHA-256 hash
        s3_client.upload_fileobj(
            Fileobj=stream_wrapper,
            Bucket=s3_bucket,
            Key=s3_key,
            ExtraArgs={'Metadata': {'sha256': sha256_hash.hexdigest()}}
        )
        #s3_client.upload_fileobj(response.raw, s3_bucket, s3_key)
        print(f"Successfully uploaded {s3_key} to S3")


def main():
    repo_url = f"{ARTIFACTORY_URL}/{ARTIFACTORY_REPO}"
    files = get_artifactory_files(repo_url)
    for file_uri in files:
        file_url = f"{repo_url}/{file_uri}" #f"{repo_url}{file_uri}"
        print("file_url...", file_url)
        s3_key = f"{ARTIFACTORY_REPO}/{file_uri}" #file_uri.lstrip('/')  # Adjust as necessary for your S3 structure
        print("s3_key...", s3_key)        
        upload_file_to_s3(file_url, AWS_S3_BUCKET, s3_key)

if __name__ == "__main__":
    main()
