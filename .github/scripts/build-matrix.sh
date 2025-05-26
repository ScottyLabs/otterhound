#!/bin/bash

# Build deployment matrix based on changed files or manual inputs
# Usage: build-matrix.sh [manual_services] [manual_environments] [changed_services_json] [changed_environments_json]

set -e

get_all_services() {
  local services
  services=$(find services -maxdepth 1 -type d ! -path services | cut -d/ -f2 | jq -R -s -c 'split("\n")[:-1]')
  echo "$services"
}

# Convert comma-separated string to JSON array
parse_comma_separated() {
  local input="$1"
  if [ -z "$input" ]; then
    echo "[]"
  else
    echo "$input" | tr ',' '\n' | jq -R -s -c 'split("\n")[:-1]'
  fi
}

# Extract service names from changed service paths (services/foo → foo)
parse_changed_services() {
  echo "$1" | jq -c 'map(split("/")[1]) // []'
}

# Extract environment names from changed environment files (environments/dev.tfvars → dev)
parse_changed_environments() {
  echo "$1" | jq -c 'map(split("/")[1] | split(".")[0]) // []'
}

build_manual_matrix() {
  local services="$1"
  local environments="$2"
  local all_services="$3"
  local matrix='{"include":[]}'

  # Use all services if none specified
  if [ "$services" = "[]" ]; then
    services="$all_services"
  fi

  # Build matrix
  for service in $(echo "$services" | jq -r '.[]'); do
    for env in $(echo "$environments" | jq -r '.[]'); do
      matrix=$(echo "$matrix" | jq --arg s "$service" --arg e "$env" '.include += [{"service": $s, "environment": $e}]')
    done
  done

  echo "$matrix" | jq -c '.'
}

build_automatic_matrix() {
  local changed_services="$1"
  local changed_environments="$2"
  local all_services="$3"
  local matrix='{"include":[]}'

  # For each changed service, add all environments
  for service in $(echo "$changed_services" | jq -r '.[]'); do
    for env in dev staging prod; do
      matrix=$(echo "$matrix" | jq --arg s "$service" --arg e "$env" '.include += [{"service": $s, "environment": $e}]')
    done
  done

  # For each changed environment, add all services
  for env in $(echo "$changed_environments" | jq -r '.[]'); do
    for service in $(echo "$all_services" | jq -r '.[]'); do
      # Only add if this combination doesn't already exist (deduplication)
      exists=$(echo "$matrix" | jq --arg s "$service" --arg e "$env" '.include | map(select(.service == $s and .environment == $e)) | length')
      if [ "$exists" = "0" ]; then
        matrix=$(echo "$matrix" | jq --arg s "$service" --arg e "$env" '.include += [{"service": $s, "environment": $e}]')
      fi
    done
  done

  echo "$matrix" | jq -c '.'
}

main() {
  local manual_services="${1:-}"
  local manual_environments="${2:-}"
  local changed_services_json="${3:-[]}"
  local changed_environments_json="${4:-[]}"

  # Get all available services from filesystem
  local all_services
  all_services=$(get_all_services)
  echo "Found services: $all_services" >&2

  # Auto-detect mode based on whether manual inputs are provided
  if [ -n "$manual_services" ] || [ -n "$manual_environments" ]; then
    # Manual dispatch mode - use workflow inputs
    echo "Manual mode" >&2
    local services environments matrix

    services=$(parse_comma_separated "$manual_services")
    environments=$(parse_comma_separated "$manual_environments")

    echo "Parsed services: $services" >&2
    echo "Parsed environments: $environments" >&2

    matrix=$(build_manual_matrix "$services" "$environments" "$all_services")

    echo "$matrix"
  else
    # Automatic mode - use file change detection
    echo "Automatic mode" >&2
    local changed_services changed_environments matrix

    changed_services=$(parse_changed_services "$changed_services_json")
    changed_environments=$(parse_changed_environments "$changed_environments_json")

    echo "Changed services: $changed_services" >&2
    echo "Changed environments: $changed_environments" >&2

    matrix=$(build_automatic_matrix "$changed_services" "$changed_environments" "$all_services")

    echo "$matrix"
  fi
}

# Run main function with all arguments
main "$@"
