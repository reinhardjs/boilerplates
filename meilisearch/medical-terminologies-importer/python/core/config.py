class Config:
    BATCH_SIZE = 5000
    NUM_WORKERS = 5
    MAX_RETRIES = 3
    RETRY_DELAY = 0.3
    LOG_INTERVAL = 100000
    BATCH_INTERVAL = 0.001
    INDEX_NAME = "terminologies"
    SOURCE_TYPE_LOCAL = "local"
    SOURCE_TYPE_BUCKET = "bucket"
