#!/bin/bash

# Source common functions
source "$(dirname "$0")/_common.sh"

# Validate arguments
validate_args "$1" "$2"

# Plan the service changes
change_to_service_dir "$1"
tofu plan -var-file="$(get_vars_file "$2")"
