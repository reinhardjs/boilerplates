package main

import (
	"bufio"
	"context"
	"fmt"
	"log"
	"os"
	"snomedct-importer/reader"
	"strings"
	"sync"
	"sync/atomic"
	"time"

	"github.com/joho/godotenv"
	"github.com/meilisearch/meilisearch-go"
	"github.com/shirou/gopsutil/process"
)

type MeiliDocument struct {
	ID       string      `json:"id"`
	Code     string      `json:"code"`
	Display  string      `json:"display"`
	Context  string      `json:"context"`
	Metadata interface{} `json:"metadata"`
}

const (
	batchSize          = 5000 // Reduce batch size to lower memory usage
	numWorkers         = 5    // Reduced workers to lower memory footprint
	maxRetries         = 3
	retryDelay         = 300 * time.Millisecond
	logInterval        = 10000
	batchInterval      = 1 * time.Millisecond // Add delay between batches
	recordHeaderLength = 9                    // Length of record's header
	hasHeader          = true                 // Assume the file has a header; change this flag as needed
	indexName          = "terminologies"
	contextStr         = "snomed-ct"
	documentIdPrefix   = "snomed-ct-description"
	fileName           = "sct2_Description_Full_GermanyEdition_20240515.txt"
	sourceTypeLocal    = "local"
	sourceTypeBucket   = "bucket"
)

type FileReader interface {
	GetScanner() (*bufio.Scanner, error)
	Close() error
}

func openFileAndInitializeScanner(sourceType, fileName string, hasHeader bool) (FileReader, *bufio.Scanner, error) {
	var fileReader FileReader
	var err error

	switch sourceType {
	case sourceTypeLocal:
		fileReader, err = reader.NewLocalFileReader(fileName)
	case sourceTypeBucket:
		bucketName := os.Getenv("BUCKET_NAME_PRIVATE")
		ctx := context.Background()
		fileReader, err = reader.NewBucketFileReader(ctx, bucketName, os.Getenv("FILE_KEY_BASE_DIR")+"/"+fileName)
	default:
		return nil, nil, fmt.Errorf("unsupported source type: %s", sourceType)
	}

	if err != nil {
		return nil, nil, err
	}

	scanner, err := fileReader.GetScanner()
	if err != nil {
		fileReader.Close()
		return nil, nil, err
	}

	if hasHeader {
		if !scanner.Scan() {
			fileReader.Close()
			return nil, nil, fmt.Errorf("error reading header: %v", scanner.Err())
		}
	}

	return fileReader, scanner, nil
}

func processDescriptionRecords(scanner *bufio.Scanner, recordHeaderLength int, documentIdPrefix, contextStr string, batchSize int, recordsChan chan []MeiliDocument, batch *[]MeiliDocument, batchMutex *sync.Mutex) {
	for scanner.Scan() {
		record := strings.Split(scanner.Text(), "\t")
		if len(record) < recordHeaderLength {
			continue
		}

		meiliId := documentIdPrefix + "-" + record[0] + "-" + record[1]

		doc := MeiliDocument{
			ID:      meiliId,
			Code:    record[4],
			Display: record[7],
			Context: contextStr,
			Metadata: map[string]interface{}{
				"id":                 record[0],
				"effectiveTime":      record[1],
				"active":             record[2],
				"moduleId":           record[3],
				"conceptId":          record[4],
				"languageCode":       record[5],
				"typeId":             record[6],
				"term":               record[7],
				"caseSignificanceId": record[8],
			},
		}

		batchMutex.Lock()
		*batch = append(*batch, doc)
		if len(*batch) >= batchSize {
			recordsChan <- *batch
			*batch = make([]MeiliDocument, 0, batchSize)
		}
		batchMutex.Unlock()
	}
}

func main() {
	err := godotenv.Load()
	if err != nil {
		log.Fatalf("Error loading .env file")
	}

	sourceType := os.Getenv("SOURCE_TYPE")
	if sourceType == "" {
		sourceType = sourceTypeLocal
	}

	meiliHost, meiliAPIKey := getMeiliConfig()
	startTime := time.Now()

	process, err := process.NewProcess(int32(os.Getpid()))
	if err != nil {
		log.Fatalf("Error getting process: %v", err)
	}

	fileReader, scanner, err := openFileAndInitializeScanner(sourceType, fileName, hasHeader)
	if err != nil {
		log.Fatalf("Error initializing file reader: %v", err)
	}
	defer fileReader.Close()

	client := meilisearch.New(meiliHost, meilisearch.WithAPIKey(meiliAPIKey))
	index := client.Index(indexName)

	var (
		wg             sync.WaitGroup
		recordsChan    = make(chan []MeiliDocument)
		totalProcessed uint64
		batchMutex     sync.Mutex
	)

	startWorkers(numWorkers, &wg, recordsChan, index, &totalProcessed, logInterval, batchInterval, maxRetries, retryDelay, process)

	batch := make([]MeiliDocument, 0, batchSize)

	processDescriptionRecords(scanner, recordHeaderLength, documentIdPrefix, contextStr, batchSize, recordsChan, &batch, &batchMutex)

	if err := scanner.Err(); err != nil {
		log.Printf("Error scanning file: %v", err)
	}

	sendRemainingRecords(recordsChan, &batch, &batchMutex)

	close(recordsChan)
	wg.Wait()

	logCompletion(startTime, totalProcessed, process)
}

func getMeiliConfig() (string, string) {
	meiliHost := os.Getenv("MEILI_HOST")
	if meiliHost == "" {
		meiliHost = "http://localhost:7700"
	}
	meiliAPIKey := os.Getenv("MEILI_API_KEY")
	if meiliAPIKey == "" {
		meiliAPIKey = "master-key"
	}
	return meiliHost, meiliAPIKey
}

func startWorkers(numWorkers int, wg *sync.WaitGroup, recordsChan chan []MeiliDocument, index meilisearch.IndexManager, totalProcessed *uint64, logInterval, batchInterval time.Duration, maxRetries int, retryDelay time.Duration, process *process.Process) {
	for i := 0; i < numWorkers; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			for batch := range recordsChan {
				for retry := 0; retry < maxRetries; retry++ {
					if _, err := index.AddDocuments(batch); err == nil {
						atomic.AddUint64(totalProcessed, uint64(len(batch)))
						if atomic.LoadUint64(totalProcessed)%uint64(logInterval) == 0 {
							log.Printf("Processed %d records", atomic.LoadUint64(totalProcessed))
							memInfo, _ := process.MemoryInfo()
							if memInfo != nil {
								log.Printf("Memory usage by this process: %v MB", memInfo.RSS/1024/1024)
							} else {
								log.Printf("Error retrieving memory info")
							}
						}
						break
					} else if retry < maxRetries-1 {
						time.Sleep(retryDelay)
					} else {
						log.Printf("Error: Failed to add batch after %d retries: %v", maxRetries, err)
					}
				}
				time.Sleep(batchInterval)
			}
		}()
	}
}

func sendRemainingRecords(recordsChan chan []MeiliDocument, batch *[]MeiliDocument, batchMutex *sync.Mutex) {
	batchMutex.Lock()
	if len(*batch) > 0 {
		recordsChan <- *batch
	}
	batchMutex.Unlock()
}

func logCompletion(startTime time.Time, totalProcessed uint64, process *process.Process) {
	duration := time.Since(startTime)
	log.Printf("Completed processing %d total records in %v", atomic.LoadUint64(&totalProcessed), duration)
	memInfo, _ := process.MemoryInfo()
	log.Printf("Final memory usage by this process: %v MB", memInfo.RSS/1024/1024)
}
