#!/bin/bash

# Build deployment matrix based on changed files
# Usage: build-matrix.sh [changed_services_json] [changed_environments_json]

set -e

# Function to get all available services
get_all_services() {
  find services -maxdepth 1 -type d ! -path services | cut -d/ -f2 | jq -R -s -c 'split("\n")[:-1]'
}

# Function to extract service names from changed service paths
parse_changed_services() {
  local changed_services_json="$1"
  if [ "$changed_services_json" = "[]" ] || [ -z "$changed_services_json" ]; then
    echo "[]"
  else
    # services/service_name -> service_name
    echo "$changed_services_json" | jq -c 'map(split("/")[1])'
  fi
}

# Function to extract environment names from changed environment files
parse_changed_environments() {
  local changed_environments_json="$1"
  if [ "$changed_environments_json" = "[]" ] || [ -z "$changed_environments_json" ]; then
    echo "[]"
  else
    # environments/environment_name.tfvars -> environment_name.tfvars -> environment_name
    echo "$changed_environments_json" | jq -c 'map(split("/")[1] | split(".")[0])'
  fi
}

# Function to build the deployment matrix
build_matrix() {
  local changed_services="$1"
  local changed_environments="$2"
  local all_services="$3"

  local matrix='{"include":[]}'

  # For each changed service, add all environments
  for service in $(echo "$changed_services" | jq -r '.[]'); do
    for env in dev staging prod; do
      matrix=$(echo "$matrix" | jq --arg service "$service" --arg env "$env" '.include += [{"service": $service, "environment": $env}]')
    done
  done

  # For each changed environment, add all services
  for env in $(echo "$changed_environments" | jq -r '.[]'); do
    for service in $(echo "$all_services" | jq -r '.[]'); do
      # Only add if this combination doesn't already exist
      local exists=$(echo "$matrix" | jq --arg service "$service" --arg env "$env" '.include | map(select(.service == $service and .environment == $env)) | length')
      if [ "$exists" = "0" ]; then
        matrix=$(echo "$matrix" | jq --arg service "$service" --arg env "$env" '.include += [{"service": $service, "environment": $env}]')
      fi
    done
  done

  echo "$matrix"
}

main() {
  local changed_services_json="${1:-[]}"
  local changed_environments_json="${2:-[]}"

  # Get all available services
  local all_services
  all_services=$(get_all_services)

  # Parse changed files
  local changed_services
  changed_services=$(parse_changed_services "$changed_services_json")

  local changed_environments
  changed_environments=$(parse_changed_environments "$changed_environments_json")

  # Debug output for GitHub Actions logs
  echo "All services: $all_services" >&2
  echo "Changed services: $changed_services" >&2
  echo "Changed environments: $changed_environments" >&2

  # Build and output the matrix
  local matrix
  matrix=$(build_matrix "$changed_services" "$changed_environments" "$all_services")

  echo "Final matrix: $matrix" >&2
  echo "$matrix"
}

# Run main function with all arguments
main "$@"
