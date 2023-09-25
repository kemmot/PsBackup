<#
.SYNOPSIS
Invokes a backup operation.

.OUTPUTS
None.

.PARAMETER Config
The configuration to use for the backup.
#>
function Invoke-Backup() {
    Param (
        [PsBackupConfig] $Config
    )
    Process {
        function New-TemporaryDirectory {
            $Parent = [System.IO.Path]::GetTempPath()
            $Name = [System.IO.Path]::GetRandomFileName()
            return New-Item -ItemType:Directory -Path:(Join-Path $Parent $Name)
        }
        
        $TempFolder = New-TemporaryDirectory
        Write-Host "Created temp folder: $TempFolder"
        
        foreach ($File in $Config.Files) {
            Copy-Item -Path:$File -Destination:$TempFolder
            Write-Host "Copied file: $File"
        }
        
        # create archive
        if (-not (Test-Path $global:PsBackupSettings.BackupFolder)) {
            New-Item -ItemType:Directory -Path:$global:PsBackupSettings.BackupFolder | Out-Null
            Write-Host "Created backup folder: $($global:PsBackupSettings.BackupFolder)"
        }
        
        $ArchivePath = (Join-Path $global:PsBackupSettings.BackupFolder $Config.Name) + '.zip'
        Compress-Archive -Path:"$TempFolder\*" -DestinationPath:$ArchivePath
        Write-Host "Created zip: $ArchivePath"
        
        # clean up
        Remove-Item $TempFolder -Recurse
        Write-Host "Deleted temp folder: $TempFolder"
    }
}