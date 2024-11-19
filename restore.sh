#!/bin/bash

# Source the backup_restore_lib.sh to get access to the functions
source "$(dirname "$0")/backup_restore_lib.sh"


# Validate restore parameters
validate_restore_params  # Validate input parameters

# Proceed with the restore process if parameters are valid
restore
