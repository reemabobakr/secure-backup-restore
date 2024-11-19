#!/bin/bash

# Source the backup_restore_lib.sh to get access to the functions
source ./backup_restore_lib.sh

# Validate backup parameters
validate_backup_params  # Validate input parameters

# Proceed with the backup process if parameters are valid
backup
