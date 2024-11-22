package reader

import (
	"bufio"
	"context"
	"fmt"
	"os"

	"cloud.google.com/go/storage"
	"google.golang.org/api/option"
)

type BucketFileReader struct {
	reader *storage.Reader
}

func NewBucketFileReader(ctx context.Context, bucketName, objectName string) (*BucketFileReader, error) {
	credentialsPath := os.Getenv("GOOGLE_APPLICATION_CREDENTIALS_PATH")
	if credentialsPath == "" {
		return nil, fmt.Errorf("GOOGLE_APPLICATION_CREDENTIALS_PATH environment variable not set")
	}

	credentials, err := os.ReadFile(credentialsPath)
	if err != nil {
		return nil, err
	}

	client, err := storage.NewClient(ctx, option.WithCredentialsJSON(credentials))
	if err != nil {
		return nil, err
	}

	reader, err := client.Bucket(bucketName).Object(objectName).NewReader(ctx)
	if err != nil {
		return nil, err
	}

	return &BucketFileReader{reader: reader}, nil
}

func (r *BucketFileReader) GetScanner() (*bufio.Scanner, error) {
	scanner := bufio.NewScanner(r.reader)
	scanner.Buffer(make([]byte, 0, bufio.MaxScanTokenSize), bufio.MaxScanTokenSize)
	return scanner, nil
}

func (r *BucketFileReader) Close() error {
	return r.reader.Close()
}
