package main

import (
	"encoding/csv"
	"fmt"
	"math/rand"
	"os"
	"time"

	"github.com/bxcodec/faker/v4"
)

func generateCustomerData(numRecords int) [][]string {
	var customerData [][]string
	for i := 0; i < numRecords; i++ {
		firstName := faker.FirstName()
		lastName := faker.LastName()
		company := ""
		if rand.Intn(2) == 0 {
			company = "company corp"
		}
		phone := faker.Phonenumber() // Corrected method name
		timestamp := time.Now().UnixNano()
		email := fmt.Sprintf("%s+%d@%s", faker.Username(), timestamp, faker.DomainName())
		group := []string{"VIP", "Regular", ""}[rand.Intn(3)]
		gender := []string{"Male", "Female"}[rand.Intn(2)]
		birthday := faker.Date()

		customerData = append(customerData, []string{firstName, lastName, company, phone, email, group, gender, birthday})
	}
	return customerData
}

func writeToCSV(filename string, data [][]string) error {
	file, err := os.Create(filename)
	if err != nil {
		return err
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	writer.Comma = ';'
	err = writer.Write([]string{"First Name", "Last Name", "Company", "Phone", "Email", "Group", "Gender", "Birthday"})
	if err != nil {
		return err
	}
	writer.WriteAll(data)
	writer.Flush() // Ensure all data is written to the file
	return writer.Error()
}

func main() {
	rand.Seed(time.Now().UnixNano())
	numRecords := 10000
	filename := "10k_customers.csv"

	customerData := generateCustomerData(numRecords)
	err := writeToCSV(filename, customerData)
	if err != nil {
		fmt.Printf("Error writing to CSV: %v\n", err)
	} else {
		fmt.Println("CSV file created successfully!")
	}
}
