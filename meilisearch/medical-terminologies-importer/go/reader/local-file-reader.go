package reader

import (
	"bufio"
	"os"
)

type LocalFileReader struct {
	file *os.File
}

func NewLocalFileReader(fileName string) (*LocalFileReader, error) {
	file, err := os.Open(fileName)
	if err != nil {
		return nil, err
	}
	return &LocalFileReader{file: file}, nil
}

func (r *LocalFileReader) GetScanner() (*bufio.Scanner, error) {
	scanner := bufio.NewScanner(r.file)
	scanner.Buffer(make([]byte, 0, bufio.MaxScanTokenSize), bufio.MaxScanTokenSize)
	return scanner, nil
}

func (r *LocalFileReader) Close() error {
	return r.file.Close()
}
