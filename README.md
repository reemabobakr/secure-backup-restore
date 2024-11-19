
# Backup and Restore Tool

## Overview
This tool allows you to create encrypted backups of directories and restore them. It supports both local and remote backup functionality to an EC2 instance. The backup is created using `tar` for archiving and `gpg` for encryption.

## Files Included
- **backup.sh**: Script for creating a backup.
- **restore.sh**: Script for restoring a backup.
- **backup_restore_lib.sh**: Library of functions used by both `backup.sh` and `restore.sh`.

## Setup

Before you can use the tool, ensure that the following dependencies are installed:
- `tar`
- `gpg`
- `scp`

Also, ensure you have access to an EC2 instance or any remote server for storing backups.

## Usage

### 1. **Create a Backup**

To create a backup of a directory, run the `backup.sh` script:

```bash
./backup.sh
```

The script will prompt you for the following inputs:
- **Source Directory**: The directory you want to back up.
- **Destination Directory**: The location where the backup will be stored (local or remote).
- **Encryption Key**: A key to encrypt the backup file.
- **Number of Days (Optional)**: If you want to back up only files modified within a specific number of days, enter the number.

### Example:

```bash
Enter the source directory to backup:
./mydata
Enter the destination directory for the backup:
./backups
Enter the encryption key:
my_secure_key
Enter the number of days to backup modified files (n):
7
```

### 2. **Restore a Backup**

To restore a backup from the destination, run the `restore.sh` script:

```bash
./restore.sh
```

The script will prompt you for the following:
- **Encrypted Backup File**: The path to the `.gpg` backup file you want to restore.
- **Destination Directory**: The directory where the backup will be restored.
- **Decryption Key**: The passphrase used to decrypt the backup file.

### Example:

```bash
Enter the encrypted backup file to restore:
./backups/my_backup_2024_11_19_14_20_35.tar.gz.gpg
Enter the destination directory for the restore:
./restored_data
Enter the decryption key:
my_secure_key
```

## Remote Backup (EC2)

To back up files to a remote EC2 instance, ensure that the following are in place:
- You have an **EC2 public IP address**.
- **SSH keys** are set up for authentication (`.pem` file).

The backup will be automatically transferred to the EC2 instance using `scp` if the backup destination is set to remote.

## Assumptions
- You have the necessary permissions to read/write to the directories involved.
- The EC2 instance is accessible at the time of backup.
- The provided encryption key is secure and valid.

## Troubleshooting
- **Backup Script Fails**: Ensure the source directory exists and is accessible.
- **Restore Script Fails**: Ensure the backup file exists and is in the correct format (.gpg).
- **Remote Server Issues**: Check the network connectivity and the EC2 instance's availability.



