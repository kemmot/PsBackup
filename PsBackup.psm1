Write-Verbose 'Running PsBackup.psm1'
$path = Split-Path $script:MyInvocation.MyCommand.Path
Push-Location $path

class PsBackupConfig
{
    [string] $Name;
    [string[]]$Files = @();
}

if (!(Test-Path variable:Global:GitWorkingCopyStack)) {
    $global:PsBackupSettings = @{}
    $global:PsBackupSettings.BackupFolder = ''
}

. .\Invoke-Backup.ps1
. .\New-BackupConfig.ps1

Pop-Location
