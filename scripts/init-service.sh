#!/bin/bash

# Source common functions
source "$(dirname "$0")/_common.sh"

# Validate arguments
validate_args "$1" "$2"

# Initialize the service
change_to_service_dir "$1"
tofu init -backend-config="$(get_backend_config "$2")"
