#!/bin/bash

# Import books from Aozora Bunko

set -e

echo "Starting Aozora Bunko import..."

# Change to server directory
cd "$(dirname "$0")/.."

# Check if CSV file exists
if [ ! -f "list_person_all_extended_utf8.csv" ]; then
    echo "Error: CSV file 'list_person_all_extended_utf8.csv' not found!"
    echo "Please download it from: https://www.aozora.gr.jp/index_pages/person_all_extended_utf8.zip"
    echo "Extract and place the CSV file in the server directory."
    exit 1
fi

# Run the import script
echo "Running import script..."
go run import_aozora.go

echo "Import completed!"