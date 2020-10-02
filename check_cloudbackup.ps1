<#
.SYNOPSIS
    Check Windows Azure Backup last scheduled job status.
.DESCRIPTION
    Check Windows Azure Backup and returns Nagios output and code.
PARAMETER Hours
    Number of hours since now to check for backup jobs.
    Default 48.
.OUTPUTS
    OK: All last backups jobs within $Hours successful.
    CRITICAL: Backup job failed.
.EXAMPLE
    .\check_cloudbackup.ps1 -Hours 96
Based on check_wsb.ps1 by Juan Granados 
#>
Param(    
    [Parameter(Mandatory=$false,Position=0)] 
    [ValidateNotNullOrEmpty()]
    [int]$Hours=48
)

# Set specific subscription
Select-AzSubscription -Subscription "XXXX" | Out-Null

# Get Vault
$Vault = Get-AzRecoveryServicesVault

# Get backup status
try{
    $BackupStatus = Get-AzRecoveryServicesBackupJob -VaultId $Vault.ID -ErrorAction Stop
}catch{
    Write-Output "UNKNOWN: Could not get Windows Azure Backup" 
    $host.SetShouldExit(3)
}
if ($BackupStatus){

Foreach($Status in $BackupStatus) {

    # Check last backup
    $LastSuccessfulBackupTime = ($Status.EndTime).Date
    # If there is a last backup
    If ($LastSuccessfulBackupTime){

        # If last backup has been performed in time and its result is ok.
        If ( (($Status.EndTime).Date -ge (get-date).AddHours(-$($Hours))) -and $Status.Status -eq 'Completed'){
            Write-Output "OK: last backup date $($Status.EndTime)." 
            $host.SetShouldExit(0)
        }

        # If last backup was not performed in time.
        ElseIf ( ($Status.EndTime).Date -le (get-date).AddHours(-$($Hours)) ){
            Write-Output "WARNING: last backup date $($Status.EndTime)." 
            $host.SetShouldExit(1)
            break
        }

        # If last backup failed
        ElseIf ( ($Status.Status) -eq 'Failed' ){
            Write-Output "CRITICAL: Last backup ending $($Status.EndTime) failed." 
            $host.SetShouldExit(2)
            break
        }

        Else{
            Write-Output "UNKNOWN: Unknown status" 
            $host.SetShouldExit(3)
        }
    }
    else{
        Write-Output "CRITICAL: There is not any successful backup yet." 
        $host.SetShouldExit(2)
    }
}
}
Else{
    Write-Output "UNKNOWN: Could not get Windows Server Backup information." 
    $host.SetShouldExit(3)
}
