#!/bin/bash

# Function to validate backup parameters
validate_backup_params() {
  # Read user input for each parameter
  echo "Enter the source directory to backup:"
  read SOURCE_DIR
  SOURCE_DIR=$(echo "$SOURCE_DIR" | sed 's/[[:space:]:]/_/g')  # Replace whitespace and colon with underscores

  # Validate source directory
  if [ ! -d "$SOURCE_DIR" ]; then
    echo "Error: Source directory '$SOURCE_DIR' does not exist."
    exit 1
  fi

  echo "Enter the destination directory for the backup:"
  read DEST_DIR
  DEST_DIR=$(echo "$DEST_DIR" | sed 's/[[:space:]:]/_/g')  # Replace whitespace and colon with underscores

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
  read ENCRYPTION_KEY  # Using -s to hide the key input

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
  # TIMESTAMP=$(date +"%Y_%m_%d_%H_%M_%S")
  # TIMESTAMP=$(echo "$TIMESTAMP" | sed 's/[[:space:]:]/_/g')  # Replace spaces and colons with underscores
  TIMESTAMP=$(date +"%Y_%m_%d_%H_%M_%S" | sed 's/[[:space:]:]/_/g')
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
  EC2_PUBLIC_IP="13.48.135.193"  # Replace with your EC2 instance's public IP
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


# # Function to validate restore parameters
# validate_restore_params() {
#   echo "Enter the encrypted backup file to restore:"
#   read ENCRYPTED_BACKUP_FILE
#   ENCRYPTED_BACKUP_FILE=$(echo "$ENCRYPTED_BACKUP_FILE" | sed 's/[[:space:]:]/_/g')  # Replace whitespace and colons with underscores

#   # Validate encrypted backup file
#   if [ ! -f "$ENCRYPTED_BACKUP_FILE" ]; then
#     echo "Error: Encrypted backup file '$ENCRYPTED_BACKUP_FILE' does not exist."
#     exit 1
#   fi

#   echo "Enter the destination directory for the restored files:"
#   read RESTORE_DEST_DIR
#   RESTORE_DEST_DIR=$(echo "$RESTORE_DEST_DIR" | sed 's/[[:space:]:]/_/g')  # Replace whitespace and colons with underscores


  

#   echo "Enter the decryption key:"
#   read DECRYPTION_KEY  

#   # Validate decryption key
#   if [ -z "$DECRYPTION_KEY" ]; then
#     echo "Error: Decryption key cannot be empty."
#     exit 1
#   fi



#   # Validate or create restore destination directory
#   if [ ! -d "$RESTORE_DEST_DIR" ]; then
#     echo "Restore destination directory '$RESTORE_DEST_DIR' does not exist. Creating it."
#     mkdir -p "$RESTORE_DEST_DIR"
#   fi
# }

# # # Function to perform restore operations
# restore() {
#  # Create a temp directory under the restore destination
#   TEMP_DIR="$RESTORE_DEST_DIR/temp_restore"
#   mkdir -p "$TEMP_DIR"


#   # Decrypt the backup file
#   DECRYPTED_FILE="${ENCRYPTED_BACKUP_FILE%.gpg}"  # Remove .gpg extension
#   echo "$DECRYPTION_KEY" | gpg --batch --yes --passphrase-fd 0 --decrypt -o "$DECRYPTED_FILE" "$ENCRYPTED_BACKUP_FILE"

#   if [ "$?" -ne 0 ]; then
#     echo "Error: Failed to decrypt the backup file. Check the decryption key."
#     exit 1
#   fi

#   # Extract the decrypted backup file to the restore destination
#   tar -xzf "$DECRYPTED_FILE" -C "$RESTORE_DEST_DIR"

#   if [ "$?" -eq 0 ]; then
#     echo "Restore completed successfully. Files have been restored to '$RESTORE_DEST_DIR'."
#   else
#     echo "Error: Failed to extract the backup file."
#     exit 1
#   fi
#   # Cleanup: Delete the temporary directory
#   rm -rf "$TEMP_DIR"

# }




#!/bin/bash

# Function to validate restore parameters
validate_restore_params() {
  echo "Enter the remote server address (e.g., user@host):"
  read REMOTE_SERVER

  echo "Enter the path to the encrypted backup file on the remote server:"
  read REMOTE_BACKUP_PATH

  # Validate remote backup file path
  if [ -z "$REMOTE_BACKUP_PATH" ]; then
    echo "Error: Remote backup file path cannot be empty."
    exit 1
  fi

  echo "Enter the destination directory for the restored files:"
  read RESTORE_DEST_DIR
  RESTORE_DEST_DIR=$(echo "$RESTORE_DEST_DIR" | sed 's/[[:space:]:]/_/g')  # Replace whitespace and colons with underscores

  echo "Enter the path to the private SSH key for authentication (or press Enter to skip):"
  read SSH_KEY_PATH

  # Validate or create restore destination directory
  if [ ! -d "$RESTORE_DEST_DIR" ]; then
    echo "Restore destination directory '$RESTORE_DEST_DIR' does not exist. Creating it."
    mkdir -p "$RESTORE_DEST_DIR"
  fi

  echo "Enter the decryption key:"
  read DECRYPTION_KEY  

  # Validate decryption key
  if [ -z "$DECRYPTION_KEY" ]; then
    echo "Error: Decryption key cannot be empty."
    exit 1
  fi
}

restore() {
  echo "Copying encrypted backup directory from remote server..."
  
  # Define the local path for the backup directory
  LOCAL_BACKUP_DIR="$RESTORE_DEST_DIR/$(basename "$REMOTE_BACKUP_PATH")"

  if [ -n "$SSH_KEY_PATH" ]; then
    scp -i "$SSH_KEY_PATH" -r "$REMOTE_SERVER:$REMOTE_BACKUP_PATH" "$RESTORE_DEST_DIR"
  else
    scp -r "$REMOTE_SERVER:$REMOTE_BACKUP_PATH" "$RESTORE_DEST_DIR"
  fi

  if [ "$?" -ne 0 ]; then
    echo "Error: Failed to copy the backup directory from the remote server."
    exit 1
  fi

  # Process each encrypted file in the backup directory
  echo "Decrypting files in the backup directory..."
  for ENCRYPTED_BACKUP_FILE in "$LOCAL_BACKUP_DIR"/*.gpg; do
    if [ ! -f "$ENCRYPTED_BACKUP_FILE" ]; then
      echo "No encrypted files found in the backup directory."
      exit 1
    fi

    # Decrypt each file
    DECRYPTED_FILE="${ENCRYPTED_BACKUP_FILE%.gpg}"  # Remove .gpg extension
    echo "$DECRYPTION_KEY" | gpg --batch --yes --passphrase-fd 0  --decrypt -o "$DECRYPTED_FILE" "$ENCRYPTED_BACKUP_FILE"

    if [ "$?" -ne 0 ]; then
      echo "Error: Failed to decrypt file '$ENCRYPTED_BACKUP_FILE'. Check the decryption key."
      exit 1
    fi

    # Extract the decrypted tarball
    echo "Extracting file: $DECRYPTED_FILE"
    tar -xzf "$DECRYPTED_FILE" -C "$RESTORE_DEST_DIR"

    if [ "$?" -ne 0 ]; then
      echo "Error: Failed to extract file '$DECRYPTED_FILE'."
      exit 1
    fi

    # Optionally, clean up the decrypted tarball after extraction
    # rm -f "$DECRYPTED_FILE"
  done

  echo "Restore completed successfully. Files have been restored to '$RESTORE_DEST_DIR'."
}

# restore() {
#   echo "Copying encrypted backup directory from remote server..."
  
#   # Define the local path for the backup directory
#   LOCAL_BACKUP_DIR="$RESTORE_DEST_DIR/$(basename "$REMOTE_BACKUP_PATH")"

#   if [ -n "$SSH_KEY_PATH" ]; then
#     scp -i "$SSH_KEY_PATH" -r "$REMOTE_SERVER:$REMOTE_BACKUP_PATH" "$RESTORE_DEST_DIR"
#   else
#     scp -r "$REMOTE_SERVER:$REMOTE_BACKUP_PATH" "$RESTORE_DEST_DIR"
#   fi

#   if [ "$?" -ne 0 ]; then
#     echo "Error: Failed to copy the backup directory from the remote server."
#     exit 1
#   fi

#   # Process each encrypted file in the backup directory
#   echo "Decrypting files in the backup directory..."
#   for ENCRYPTED_BACKUP_FILE in "$LOCAL_BACKUP_DIR"/*.gpg; do
#     if [ ! -f "$ENCRYPTED_BACKUP_FILE" ]; then
#       echo "No encrypted files found in the backup directory."
#       exit 1
#     fi

#     # Decrypt each file to .tar.gz
#     DECRYPTED_FILE="${ENCRYPTED_BACKUP_FILE%.gpg}"  # Remove .gpg extension
#     # echo "$DECRYPTION_KEY" | gpg --batch --yes --passphrase-fd 0 --decrypt -o "$DECRYPTED_FILE" "$ENCRYPTED_BACKUP_FILE"
#     echo "Attempting to decrypt: $ENCRYPTED_BACKUP_FILE to $DECRYPTED_FILE"
#     echo "$DECRYPTION_KEY" | gpg --batch --yes --pinentry-mode loopback --passphrase-fd 0 --decrypt -o "$DECRYPTED_FILE" "$ENCRYPTED_BACKUP_FILE"

#     if [ "$?" -ne 0 ]; then
#       echo "Error: Failed to decrypt file '$ENCRYPTED_BACKUP_FILE'. Check the decryption key."
#       exit 1
#     fi

    
#     # Check if the decrypted file exists
#     if [ ! -f "$DECRYPTED_FILE" ]; then
#        echo "Error: Decrypted file '$DECRYPTED_FILE' does not exist after decryption."
#        exit 1
#    fi

# echo "Decrypted file created: $DECRYPTED_FILE"


#     # Extract the decrypted tarball (.tar.gz)
#     echo "Extracting file: $DECRYPTED_FILE"
#     tar -xzf "$DECRYPTED_FILE" -C "$RESTORE_DEST_DIR"

#     if [ "$?" -ne 0 ]; then
#       echo "Error: Failed to extract file '$DECRYPTED_FILE'."
#       exit 1
#     fi

#     # Optionally, clean up the decrypted .tar.gz file after extraction
#     rm -f "$DECRYPTED_FILE"
#   done

#   echo "Restore completed successfully. Files have been restored to '$RESTORE_DEST_DIR'."
# }
