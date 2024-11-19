#!/bin/bash

# Function to validate restore parameters
validate_restore_params() {
  # Check if the number of parameters is correct
  if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <backup_dir> <restore_dir> <decryption_key>"
    exit 1
  fi

  # Validate backup directory
  if [ ! -d "$1" ]; then
    echo "Error: Backup directory $1 does not exist."
    exit 1
  fi

  # Validate restore directory
  if [ ! -d "$2" ]; then
    echo "Error: Restore directory $2 does not exist."
    exit 1
  fi

  # Validate decryption key (it should not be empty)
  if [ -z "$3" ]; then
    echo "Error: Decryption key cannot be empty."
    exit 1
  fi
}

# Interactive prompts for parameters with validation
echo "Enter the backup directory:"
read -r BACKUP_DIR

# Check if backup directory exists
while [ ! -d "$BACKUP_DIR" ]; do
  echo "Error: Backup directory $BACKUP_DIR does not exist. Please enter a valid directory:"
  read -r BACKUP_DIR
done

echo "Enter the restore directory:"
read -r RESTORE_DIR

# Check if restore directory exists
while [ ! -d "$RESTORE_DIR" ]; do
  echo "Error: Restore directory $RESTORE_DIR does not exist. Please enter a valid directory:"
  read -r RESTORE_DIR
done

echo "Enter the decryption key:"
read -r DECRYPTION_KEY

# Check if decryption key is provided
while [ -z "$DECRYPTION_KEY" ]; do
  echo "Error: Decryption key cannot be empty. Please enter a valid decryption key:"
  read -r DECRYPTION_KEY
done

# Use sed to replace spaces and colons with underscores in the user input
BACKUP_DIR=$(echo "$BACKUP_DIR" | sed 's/[[:space:]:]/_/g')
RESTORE_DIR=$(echo "$RESTORE_DIR" | sed 's/[[:space:]:]/_/g')
DECRYPTION_KEY=$(echo "$DECRYPTION_KEY" | sed 's/[[:space:]:]/_/g')

# Validate the parameters
validate_restore_params "$BACKUP_DIR" "$RESTORE_DIR" "$DECRYPTION_KEY"

# Create a temporary directory for restoring
TEMP_DIR="$RESTORE_DIR/temp"
mkdir -p "$TEMP_DIR"

# Loop over all encrypted backup files and decrypt them into temp directory
for BACKUP_FILE in "$BACKUP_DIR"/*.tar.gz.gpg; do
  if [ -f "$BACKUP_FILE" ]; then
    echo "Decrypting $BACKUP_FILE..."
    gpg --batch --yes --passphrase "$DECRYPTION_KEY" -o "$TEMP_DIR/$(basename "$BACKUP_FILE" .gpg)" -d "$BACKUP_FILE"
  fi
done

# Extract the decrypted files
for DECRYPTED_FILE in "$TEMP_DIR"/*.tar.gz; do
  if [ -f "$DECRYPTED_FILE" ]; then
    echo "Extracting $DECRYPTED_FILE..."
    tar -xzf "$DECRYPTED_FILE" -C "$RESTORE_DIR"
  fi
done

# # Cleanup: remove the temp directory and its contents
# rm -rf "$TEMP_DIR"

echo "Restore completed successfully."
exit 0
