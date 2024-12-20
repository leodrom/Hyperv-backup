########## CONFIGURATION BLOCK ##########
# Define the backup directory
$backupDirectory = "D:\VM Backups"
# Define the log file path
$logFilePath = "C:\VM\Hyperv-backup\HVBackup.log"
# Define the list of VM names to include in the backup
$includedVMs = @("LEM-HomeAssistant", "LEM-Video")
# Define the number of days to keep backup files
# 0 - Keep backups indefinitely
# n - Keep backups for n days 
$backupRetentionDays = 5
########## END CONFIGURATION BLOCK ##########

# Run the script with administrative privileges in the Task Scheduler
# powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\VM\Hyperv-backup\HVBackup.ps1"

# Function to write log messages
function Write-Log {
    param (
        [string]$message,
        [string]$type = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp [$type] - $message"
    Write-Output $logMessage
    Add-Content -Path $logFilePath -Value $logMessage
}

# Function to write log messages with exception details
function Write-Log-Exception {
    param (
        [string]$message
    )
    $fullMessage = "$message Script: $($_.InvocationInfo.ScriptName), Line: $($_.InvocationInfo.ScriptLineNumber). Error: $($_.Exception.Message)"
    Write-Log -message $fullMessage -type "ERROR"
}

# Check if the script is running with administrative privileges
$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Log "The script is not running with administrative privileges. Please run the script as an administrator." "ERROR"
    exit 1
}

# Log the start of the backup process
Write-Log "===== Starting backup process ====="

# Create the backup directory if it doesn't exist
if (-not (Test-Path -Path $backupDirectory)) {
    try {
        New-Item -ItemType Directory -Path $backupDirectory
        Write-Log "Created backup directory: $backupDirectory"
    } catch {
        Write-Log "Failed to create backup directory: $backupDirectory. Error: $_" "ERROR"
        exit 1
    }
}

# Get all Hyper-V virtual machines
try {
    $ErrorActionPreference = "Stop"
    $vms = Get-VM
} catch {
    Write-Log-Exception -message ("Failed to get Hyper-V virtual machines") 
    exit 1
}

# Initialize the error names list
$errnames = @()
# Initialize the valid names list
$validnames = @()

# Check each name in the includedVMs list
foreach ($includedVM in $includedVMs) {
    if (-not ($vms.Name -contains $includedVM)) {
        $errnames += $includedVM
    }else{
        $validnames += $includedVM
    }
}

# Log the names of the machines that were not found
if ($errnames.Count -gt 0) {
    Write-Log "The following VMs were not found: $($errnames -join ', ')" "WARNING"
}

# Update the list of VMs to include only the valid names
$vms = $vms | Where-Object { $validnames -contains $_.Name }

# Create a timestamped folder for this backup session
$timestamp = Get-Date -Format "yyyyMMddHHmm"
$sessionBackupPath = Join-Path -Path $backupDirectory -ChildPath $timestamp

# Create the session backup directory
if (-not (Test-Path -Path $sessionBackupPath)) {
    try {
        New-Item -ItemType Directory -Path $sessionBackupPath
        Write-Log "Created session backup directory: $sessionBackupPath"
    } catch {
        Write-Log "Failed to create session backup directory: $sessionBackupPath. Error: $_" "ERROR"
        exit 1
    }
}

foreach ($vm in $vms) {
    # Define the backup path for the VM
    $vmBackupPath = $sessionBackupPath 

    # Create the VM backup directory if it doesn't exist
    if (-not (Test-Path -Path $vmBackupPath)) {
        try {
            New-Item -ItemType Directory -Path $vmBackupPath
            Write-Log "Created VM backup directory: $vmBackupPath"
        } catch {
            Write-Log "Failed to create VM backup directory: $vmBackupPath. Error: $_" "ERROR"
            continue
        }
    }

    # Export the VM
    try {
        $startTime = Get-Date
        Write-Log "Backing up VM: $($vm.Name)"
        Export-VM -Name $($vm.Name) -Path $vmBackupPath
        $endTime = Get-Date
        $duration = $endTime - $startTime
        $formattedDuration = "{0:mm\:ss}" -f $duration
        Write-Log "Successfully backed up VM: $($vm.Name) in $formattedDuration"
    } catch {
        Write-Log "Failed to back up VM: $($vm.Name). Error: $_" "ERROR"
    }
}

# Clean up old backup directories according to the value of $backupRetentionDays
if ($backupRetentionDays -gt 0) {
    try {
        $cutoffDate = (Get-Date).AddDays(-$backupRetentionDays)
        $backupDirs = Get-ChildItem -Path $backupDirectory -Directory

        foreach ($dir in $backupDirs) {
            if ($dir.Name -match '^\d{12}$') {
                $folderDate = [datetime]::ParseExact($dir.Name, 'yyyyMMddHHmm', $null)
                if ($folderDate -lt $cutoffDate) {
                    Remove-Item -Path $dir.FullName -Recurse -Force
                    Write-Log "Deleted old backup directory: $($dir.FullName)"
                }
            }
        }
    } catch {
        Write-Log-Exception -message ("Failed to clean up old backup directories")
    }
}

# Log the completion of the backup process
Write-Log "===== Backup completed ====="