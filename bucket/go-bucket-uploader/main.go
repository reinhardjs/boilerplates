package main

import (
	"context"
	"fmt"
	"io"
	"log"
	"os"

	"cloud.google.com/go/storage"
	"google.golang.org/api/option"
)

func uploadFileToGCS(credentialsPath, bucketName, fromFilePath, destinedFileKey string) error {
	ctx := context.Background()

	client, err := storage.NewClient(ctx, option.WithCredentialsFile(credentialsPath))
	if err != nil {
		return fmt.Errorf("failed to create client: %v", err)
	}
	defer client.Close()

	bucket := client.Bucket(bucketName)
	object := bucket.Object(destinedFileKey)
	writer := object.NewWriter(ctx)
	defer writer.Close()

	file, err := os.Open(fromFilePath)
	if err != nil {
		return fmt.Errorf("failed to open file: %v", err)
	}
	defer file.Close()

	if _, err := io.Copy(writer, file); err != nil {
		return fmt.Errorf("failed to copy file to GCS: %v", err)
	}

	return nil
}

func main() {
	if len(os.Args) != 5 {
		log.Fatalf("Usage: %s <credentials_path> <bucket_name> <from_file_path> <destined_file_key>", os.Args[0])
	}

	credentialsPath := os.Args[1]
	bucketName := os.Args[2]
	fromFilePath := os.Args[3]
	destinedFileKey := os.Args[4]

	if err := uploadFileToGCS(credentialsPath, bucketName, fromFilePath, destinedFileKey); err != nil {
		log.Fatalf("Failed to upload file to GCS: %v", err)
	}

	fmt.Println("File uploaded to Google Cloud Storage successfully!")
}
