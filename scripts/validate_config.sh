#!/bin/bash

# This script validates the feature flags JSON file
# Usage: ./validate_config.sh <config_file_path>

set -e

CONFIG_FILE="$1"

if [ -z "$CONFIG_FILE" ]; then
    echo "Error: Config file path is required"
    echo "Usage: $0 <config_file_path>"
    exit 1
fi

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Config file '$CONFIG_FILE' not found"
    exit 1
fi

echo "Validating config file: $CONFIG_FILE"

# Check if it's a valid JSON
jq empty "$CONFIG_FILE" || {
    echo "Error: Invalid JSON format"
    exit 1
}

# Check required top-level keys
for key in "flags" "values" "version"; do
    jq -e ".$key" "$CONFIG_FILE" > /dev/null || {
        echo "Error: Missing required top-level key: '$key'"
        exit 1
    }
done

# Extract flags and values for validation
FLAGS=$(jq -r '.flags | keys[]' "$CONFIG_FILE")
VALUES=$(jq -r '.values | keys[]' "$CONFIG_FILE")

# Check if all flags have corresponding values
for flag in $FLAGS; do
    echo "$VALUES" | grep -q "^$flag$" || {
        echo "Error: Flag '$flag' has no corresponding value"
        exit 1
    }
done

# Check if all values have corresponding flags
for value in $VALUES; do
    echo "$FLAGS" | grep -q "^$value$" || {
        echo "Error: Value '$value' has no corresponding flag definition"
        exit 1
    }
done

# Validate specific flag attributes
for flag in $FLAGS; do
    # Check if flag has attributes
    if jq -e ".flags.\"$flag\".attributes" "$CONFIG_FILE" > /dev/null 2>&1; then
        # Get attribute names
        ATTRS=$(jq -r ".flags.\"$flag\".attributes | keys[]" "$CONFIG_FILE")
        
        # Check if attributes are present in values
        for attr in $ATTRS; do
            jq -e ".values.\"$flag\".\"$attr\"" "$CONFIG_FILE" > /dev/null || {
                echo "Error: Flag '$flag' has attribute '$attr' but no corresponding value"
                exit 1
            }
            
            # Check attribute constraints if present
            if jq -e ".flags.\"$flag\".attributes.\"$attr\".constraints.type" "$CONFIG_FILE" > /dev/null 2>&1; then
                TYPE=$(jq -r ".flags.\"$flag\".attributes.\"$attr\".constraints.type" "$CONFIG_FILE")
                
                # Validate array type
                if [ "$TYPE" == "array" ]; then
                    jq -e ".values.\"$flag\".\"$attr\" | type == \"array\"" "$CONFIG_FILE" > /dev/null || {
                        echo "Error: Attribute '$attr' for flag '$flag' should be an array"
                        exit 1
                    }
                fi
            fi
        done
    fi
done

echo "Config file validation successful!"
exit 0