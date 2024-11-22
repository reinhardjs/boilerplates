from dotenv import load_dotenv
from core.logger import setup_logger
from google.cloud import storage

def connect_to_bucket(bucket_name: str):
    try:
        logger = setup_logger()

        # Initialize a client
        client = storage.Client()
        
        # Get the bucket object
        bucket = client.bucket(bucket_name)

        logger.info(f"Successfully connected to bucket: {bucket_name}")
        return bucket

    except Exception as e:
        logger.error(f"Failed to connect to bucket: {str(e)}")
        raise
