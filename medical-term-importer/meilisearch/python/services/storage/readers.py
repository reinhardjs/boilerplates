import io
import os
from .connect import connect_to_bucket

class FileReader:
    def __init__(self, file_path: str):
        self.file_path = file_path

    def __enter__(self):
        if not os.path.exists(self.file_path):
            raise FileNotFoundError(f"File does not exist: '{self.file_path}'")
        try:
            self.file = open(self.file_path, 'r', encoding='utf-8')
        except Exception as e:
            if self.file:
                self.file.close()
            raise e
        return self.file

    def __exit__(self, exc_type, exc_val, exc_tb):
        if self.file:
            self.file.close()

class BucketFileReader:
    def __init__(self, bucket_name: str, file_key: str):
        self.bucket = connect_to_bucket(bucket_name)
        self.blob = self.bucket.blob(file_key)

    def __enter__(self):
        return io.TextIOWrapper(self.blob.open("rb"), encoding='utf-8')

    def __exit__(self, exc_type, exc_val, exc_tb):
        pass
