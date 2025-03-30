#!/bin/bash
# This script prepares the configuration JSON file for Terraform

CONFIG_FILE="$1"
OUTPUT_FILE="$2"

if [ -z "$CONFIG_FILE" ] || [ -z "$OUTPUT_FILE" ]; then
  echo "Usage: $0 <input_json_file> <output_file>"
  exit 1
fi

# Validate JSON file
jq empty "$CONFIG_FILE" || {
  echo "Error: Invalid JSON format in $CONFIG_FILE"
  exit 1
}

# Create a properly formatted JSON file for Terraform
jq -c '.' "$CONFIG_FILE" > "$OUTPUT_FILE"

echo "Configuration prepared successfully: $OUTPUT_FILE"