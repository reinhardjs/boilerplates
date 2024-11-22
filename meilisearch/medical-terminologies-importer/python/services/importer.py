import os
import time
import threading
from concurrent.futures import ThreadPoolExecutor
import meilisearch
from dotenv import load_dotenv
from typing import List
from core.models import MeiliDocument
from core.config import Config
from services.storage.readers import FileReader, BucketFileReader
from services.parsers import Parser
from core.logger import setup_logger
import psutil  # Importing psutil for monitoring memory usage

class SnomedImporter:
    def __init__(self, args):
        load_dotenv()
        self._initialize_attributes(args)
        self.logger = setup_logger()
        self._log_initialization()

    def _initialize_attributes(self, args):
        self.total_processed = 0
        self.lock = threading.Lock()
        self.meili_client = self._init_meilisearch()
        self.context = args.context
        self.doc_type = args.doc_type
        self.file_path = args.file_path
        self.has_header = args.has_header
        self.delimiter = args.delimiter
        self.source_type = args.source_type or os.getenv('SOURCE_TYPE', Config.SOURCE_TYPE_LOCAL)
        self.parser = Parser(self.context, self.doc_type, self.delimiter)

    def _log_initialization(self):
        self.logger.info(f"Initializing {self.doc_type} importer")
        self.logger.info(f"Document type: {self.doc_type}")
        self.logger.info(f"File path: {self.file_path}")
        self.logger.info(f"Source type: {self.source_type}")

    def _init_meilisearch(self) -> meilisearch.Client:
        host = os.getenv('MEILI_HOST', 'http://localhost:7700')
        api_key = os.getenv('MEILI_API_KEY', 'master-key')
        return meilisearch.Client(host, api_key)

    def process_batch(self, batch: List[MeiliDocument]) -> None:
        batch_size = len(batch)
        for retry in range(Config.MAX_RETRIES):
            if self._try_process_batch(batch, batch_size, retry):
                break

    def _try_process_batch(self, batch, batch_size, retry):
        try:
            self.meili_client.index(Config.INDEX_NAME).add_documents([vars(doc) for doc in batch])
            self._update_processed_count(batch_size)
            return True
        except Exception as e:
            self._handle_batch_exception(e, retry)
            return False

    def _update_processed_count(self, batch_size):
        with self.lock:
            self.total_processed += batch_size
            if self.total_processed % Config.LOG_INTERVAL == 0:
                self.logger.info(f"Processed batch of {batch_size} records. Total: {self.total_processed:,}")
                self._log_memory_usage()

    def _log_memory_usage(self):
        memory_usage = psutil.Process().memory_info().rss / (1024 * 1024)  # Convert to MB
        self.logger.info(f"Current memory usage: {memory_usage:.2f} MB")

    def _handle_batch_exception(self, e, retry):
        if retry == Config.MAX_RETRIES - 1:
            self.logger.error(f"Failed to add batch after {Config.MAX_RETRIES} retries: {str(e)}")
        else:
            self.logger.warning(f"Retry {retry + 1}/{Config.MAX_RETRIES}: {str(e)}")
        time.sleep(Config.RETRY_DELAY)

    def run(self):
        start_time = time.time()
        self.logger.info("Starting import process")
        try:
            self._process_file()
        except Exception as e:
            self.logger.error(f"Import failed: {str(e)}")
            raise
        self._log_completion(start_time)

    def _process_file(self):
        reader_cls, reader_args = self._get_reader()
        batch = []
        with reader_cls(*reader_args) as file:
            self.logger.info("File opened successfully")
            if self.has_header:
                next(file)  # Skip header if present
            self._process_lines(file, batch)

    def _get_reader(self):
        if self.source_type == Config.SOURCE_TYPE_LOCAL:
            return FileReader, (self.file_path,)
        else:
            return BucketFileReader, (
                os.getenv('BUCKET_NAME_PRIVATE'),
                os.path.join(self.file_path)
            )

    def _process_lines(self, file, batch):
        with ThreadPoolExecutor(max_workers=Config.NUM_WORKERS) as executor:
            for line in file:
                doc = self.parser.parse(line.strip())
                if doc:
                    batch.append(doc)
                    if len(batch) >= Config.BATCH_SIZE:
                        executor.submit(self.process_batch, batch.copy())
                        batch.clear()
                        time.sleep(Config.BATCH_INTERVAL)
            if batch:
                executor.submit(self.process_batch, batch)

    def _log_completion(self, start_time):
        elapsed_time = time.time() - start_time
        self.logger.info(f"Import completed in {elapsed_time:.2f} seconds")
        self.logger.info(f"Total records processed: {self.total_processed:,}")
