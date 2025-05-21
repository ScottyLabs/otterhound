#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Function to check and validate a directory
validate_dir() {
    local dir="$1"
    if compgen -G "$dir/*.tf" > /dev/null; then
        echo "Validating $dir"
        (
            cd "$dir"
            tofu init -backend=false -input=false >/dev/null
            tofu validate
        )
    fi
}

# Export the function so it's available in subshells
export -f validate_dir

# Find all directories (excluding hidden like .terraform) with .tf files
find . -type f -name "*.tf" \
    -not -path "*/.terraform/*" \
    -exec dirname {} \; | sort -u | while read -r dir; do
    validate_dir "$dir"
done
