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

find . -type f -name "*.tf" \
  -not -path "*/.terraform/*" \
  -exec dirname {} \; | sort -u | while read -r dir; do
  validate_dir "$dir"
done

# Check if directories are provided via stdin
if [ -t 0 ]; then
  # No input from stdin, find all non-hidden directories with .tf files
  find . -type f -name "*.tf" \
    -not -path "*/.terraform/*" \
    -exec dirname {} \; | sort -u | while read -r dir; do
    validate_dir "$dir"
  done
else
  # Directories provided via stdin, validate only those
  while read -r dir; do
    if [ -n "$dir" ]; then
      validate_dir "$dir"
    fi
  done
fi
