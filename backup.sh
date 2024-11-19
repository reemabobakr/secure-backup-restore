#!/bin/bash

# Function to validate backup parameters
validate_backup_params() {
  # Read user input for each parameter
  echo "Enter the source directory to backup:"
  read SOURCE_DIR

   # Replace whitespace and colon with underscores
  SOURCE_DIR=$(echo "$SOURCE_DIR" | sed 's/[[:space:]:]/_/g')

  # Validate source directory
  if [ ! -d "$SOURCE_DIR" ]; then
    echo "Error: Source directory '$SOURCE_DIR' does not exist."
    exit 1
  fi

  echo "Enter the destination directory for the backup:"
  read DEST_DIR
# Replace whitespace and colon with underscores
  DEST_DIR=$(echo "$DEST_DIR" | sed 's/[[:space:]:]/_/g') 


  # Validate destination directory
  if [ ! -d "$DEST_DIR" ]; then
    echo "Destination directory '$DEST_DIR' does not exist. Creating it."
    mkdir -p "$DEST_DIR"
  fi

  if [ ! -w "$DEST_DIR" ]; then
    echo "Error: Destination directory '$DEST_DIR' is not writable."
    exit 1
  fi

  echo "Enter the encryption key:"
  read  ENCRYPTION_KEY  # Using -s to hide the key input

  # Validate encryption key
  if [ -z "$ENCRYPTION_KEY" ]; then
    echo "Error: Encryption key cannot be empty."
    exit 1
  fi

  echo "Enter the number of days to backup modified files (n):"
  read DAYS

  # Validate DAYS parameter (must be a positive integer)
  if ! [[ "$DAYS" =~ ^[0-9]+$ ]] || [ "$DAYS" -le 0 ]; then
    echo "Error: 'DAYS' parameter must be a positive integer."
    exit 1
  fi
}

# Function to perform backup operations (actual backup logic)
backup() {
  # Create timestamp and replace spaces/colons with underscores
  TIMESTAMP=$(date +"%Y_%m_%d_%H_%M_%S")
  TIMESTAMP=$(echo "$TIMESTAMP" | sed 's/[[:space:]:]/_/g')  # Replace spaces and colons with underscores
  BACKUP_DIR="$DEST_DIR/$TIMESTAMP"
  mkdir -p "$BACKUP_DIR"

  # Loop through subdirectories in the source directory
  for SUBDIR in "$SOURCE_DIR"/*; do
    if [ -d "$SUBDIR" ]; then
      MODIFIED_FILES=$(find "$SUBDIR" -type f -mtime -"$DAYS")
      if [ -n "$MODIFIED_FILES" ]; then
        DIR_NAME=$(basename "$SUBDIR")
        DIR_NAME=$(echo "$DIR_NAME" | sed 's/[[:space:]:]/_/g')  # Replace spaces and colons with underscores
        TAR_FILE="$BACKUP_DIR/${DIR_NAME}_${TIMESTAMP}.tar.gz"
        tar -czf "$TAR_FILE" -C "$SOURCE_DIR" "$DIR_NAME"
        ENCRYPTED_FILE="$TAR_FILE.gpg"
        echo "$ENCRYPTION_KEY" | gpg --batch --yes --passphrase-fd 0 --symmetric --cipher-algo AES256 -o "$ENCRYPTED_FILE" "$TAR_FILE"
        rm -f "$TAR_FILE"
      fi
    fi
  done

  # Bundle and encrypt all backups
  FINAL_BACKUP="$DEST_DIR/backup_$TIMESTAMP.tar.gz"
  tar -czf "$FINAL_BACKUP" -C "$BACKUP_DIR" .
  FINAL_ENCRYPTED="$FINAL_BACKUP.gpg"
  echo "$ENCRYPTION_KEY" | gpg --batch --yes --passphrase-fd 0 --symmetric --cipher-algo AES256 -o "$FINAL_ENCRYPTED" "$FINAL_BACKUP"
  rm -f "$FINAL_BACKUP"

  # Transfer to remote server
  REMOTE_USER="ubuntu"  # Change this to the correct user for your server
  EC2_PUBLIC_IP="51.20.189.148"  # Replace with your EC2 instance's public IP
  REMOTE_DIR="/home/ubuntu/backup"  # Replace with the correct remote directory
  KEY_PATH="/home/reem/Downloads/remote-key.pem"  # Path to your EC2 private key
  scp -i "$KEY_PATH" "$FINAL_ENCRYPTED" "$REMOTE_USER@$EC2_PUBLIC_IP:$REMOTE_DIR"

  if [ "$?" -eq 0 ]; then
    echo "Backup successfully transferred to remote server."
  else
    echo "Failed to transfer backup to remote server."
    exit 1
  fi

  echo "Backup completed successfully."
}

# Main script execution
validate_backup_params  # Validate input parameters

# Proceed with the backup process if parameters are valid
backup
















# # Validate input parameters
# if [ "$#" -ne 4 ]; then
#   echo "Usage: $0 <source_dir> <destination_dir> <encryption_key> <days>"
#   exit 1
# fi

# SOURCE_DIR=$1
# DEST_DIR=$2
# ENCRYPTION_KEY=$3
# DAYS=$4

# # Validate source directory
# if [ ! -d "$SOURCE_DIR" ]; then
#   echo "Error: Source directory $SOURCE_DIR does not exist."
#   exit 1
# fi

# # Validate or create destination directory
# if [ ! -d "$DEST_DIR" ]; then
#   echo "Destination directory $DEST_DIR does not exist. Creating it."
#   mkdir -p "$DEST_DIR"
# fi

# Create timestamp and backup directory
TIMESTAMP=$(date +"%Y_%m_%d_%H_%M_%S")
BACKUP_DIR="$DEST_DIR/$TIMESTAMP"
mkdir -p "$BACKUP_DIR"

# Loop through subdirectories
for SUBDIR in "$SOURCE_DIR"/*; do
  if [ -d "$SUBDIR" ]; then
    MODIFIED_FILES=$(find "$SUBDIR" -type f -mtime -"$DAYS")
    if [ -n "$MODIFIED_FILES" ]; then
      DIR_NAME=$(basename "$SUBDIR")
      TAR_FILE="$BACKUP_DIR/${DIR_NAME}_${TIMESTAMP}.tar.gz"

      # Create a tarball for the directory
      tar -czf "$TAR_FILE" -C "$SOURCE_DIR" "$DIR_NAME"
      
      # Check if the tarball is non-empty
      if [ -s "$TAR_FILE" ]; then
        ENCRYPTED_FILE="$TAR_FILE.gpg"
        echo "$ENCRYPTION_KEY" | gpg --batch --yes --passphrase-fd 0 --symmetric --cipher-algo AES256 -o "$ENCRYPTED_FILE" "$TAR_FILE"
        rm -f "$TAR_FILE"
        echo "Backup created and encrypted: $ENCRYPTED_FILE"
      else
        rm -f "$TAR_FILE"
        echo "Skipping empty archive for $DIR_NAME."
      fi
    else
      echo "No modified files in $SUBDIR within the last $DAYS days."
    fi
  fi
done

# Bundle all encrypted backups into one tarball
FINAL_BACKUP="$DEST_DIR/backup_$TIMESTAMP.tar.gz"
tar -czf "$FINAL_BACKUP" -C "$BACKUP_DIR" .

# Encrypt the final tarball
FINAL_ENCRYPTED="$FINAL_BACKUP.gpg"
echo "$ENCRYPTION_KEY" | gpg --batch --yes --passphrase-fd 0 --symmetric --cipher-algo AES256 -o "$FINAL_ENCRYPTED" "$FINAL_BACKUP"
rm -f "$FINAL_BACKUP"

# Transfer to remote server
REMOTE_USER="ubuntu"
EC2_PUBLIC_IP="51.20.189.148"
REMOTE_DIR="/home/ubuntu/backup"
KEY_PATH="/home/reem/Downloads/remote-key.pem"

scp -i "$KEY_PATH" "$FINAL_ENCRYPTED" "$REMOTE_USER@$EC2_PUBLIC_IP:$REMOTE_DIR"
if [ "$?" -eq 0 ]; then
  echo "Backup successfully transferred to remote server."
else
  echo "Failed to transfer backup to remote server."
  exit 1
fi

echo "Backup completed successfully."
exit 0
