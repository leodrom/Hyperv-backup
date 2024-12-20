# Hyperv-backup
# Configuration Parameters

The PowerShell script includes several configuration parameters that you can adjust to fit your backup needs:

- `$BackupPath`: Specifies the directory where the VM backups will be stored.
- `$VMNames`: An array of VM names that you want to back up. If empty, all VMs will be backed up.
- `$RetentionDays`: The number of days to keep old backups. Backups older than this value will be deleted.
- `$LogFilePath`: The path to the log file where backup operations will be recorded.

Make sure to configure these parameters in the script before running it to ensure the backup process works as expected.
This repository contains a PowerShell script for backing up Hyper-V virtual machines. The script automates the process of creating consistent backups of your VMs, ensuring that you can restore them in case of failure or data loss.

## Features
- Automated backups of Hyper-V VMs
- Consistent and reliable backup process
- Easy to configure and use

## Usage
1. Clone the repository to your local machine.
2. Open the PowerShell script and configure the backup settings as needed.
3. Run the script to start the backup process.

## Requirements
- Windows with Hyper-V enabled
- PowerShell

