Write-Verbose 'Running PsBackup.psm1'
$path = Split-Path $script:MyInvocation.MyCommand.Path
Push-Location $path

class PsBackupConfig
{
    [string] $Name;
    [string[]]$Files = @();
    [string[]]$Directories = @();
}

enum PsBackupType {
    Unknown
    Special
    Yearly
    Monthly
    Weekly
    Daily
    Extra
}

class PsBackupSet
{
    [string] $Path;
    [string] $Name;
    [datetime] $Date;
    [PsBackupType] $Type;
    [string] $Tag;
}

if (!(Test-Path variable:Global:PsBackupSettings)) {
    $global:PsBackupSettings = @{}
    $global:PsBackupSettings.BackupFolder = ''
}

. .\Invoke-Backup.ps1
. .\New-BackupConfig.ps1

function Remove-PsBackup() {
    Param (
        #[Parameter(ValueFromPipeline=$True)]
        #[PsBackupSet] $Backup,
        [switch] $Unknown,
        [switch] $Special,
        [switch] $Yearly,
        [switch] $Monthly,
        [switch] $Weekly,
        [switch] $Daily,
        [switch] $Extra,
        [switch] $All
    )
    Process {
        Get-PsBackup | Set-PsBackupType -PassThru | % {
            write-host "Backup $($_.Name) - $($_.Type)"
            switch ($_.Type) {
            [PsBackupType]::Unknown { if ($All -or $Unknown) { Write-Host "Purge Unknown backup: $($_.Name)" } }
            [PsBackupType]::Special { if ($All -or $Special) { Write-Host "Purge Special backup: $($_.Name)" } }
            [PsBackupType]::Yearly  { if ($All -or $Yearly ) { Write-Host "Purge Yearly backup: $($_.Name)" } }
            [PsBackupType]::Monthly { if ($All -or $Monthly) { Write-Host "Purge Monthly backup: $($_.Name)" } }
            [PsBackupType]::Weekly  { if ($All -or $Weekly ) { Write-Host "Purge Weekly backup: $($_.Name)" } }
            [PsBackupType]::Daily   { if ($All -or $Daily  ) { Write-Host "Purge Daily backup: $($_.Name)" } }
            [PsBackupType]::Extra   { if ($All -or $Extra  ) { Write-Host "Purge Extra backup: $($_.Name)" } }
            }
        }
    }
}

function Get-PsBackup() {
    dir $global:PsBackupSettings.BackupFolder *.zip | % {
        if ($_.Name -match '(?<name>.+?)_(?<year>\d{4})-(?<month>\d{2})-(?<day>\d{2})_(?<hour>\d{2})(?<minute>\d{2})(?<second>\d{2})(_(?<tag>.+))?\.zip') {
            $Backup = [PsBackupSet]::new()
            $Backup.Path = $_.FullName
            $Backup.Name = $_.Name
            $Backup.Date = [DateTime]::new($matches.year, $matches.month, $matches.day, $matches.hour, $matches.minute, $matches.second)
            $Backup.Tag = $matches.tag
            Write-Output $Backup
        }
    }
}

function Set-PsBackupType() {
    Param (
        [Parameter(ValueFromPipeline=$True)]
        [PsBackupSet] $Backup,
        [switch] $PassThru
    )
    Begin {
        $Backups = @()
    }
    Process {
        $Backups += $_
    }
    End {
        $LastBackup = $null
        $Backups | Sort Date | % {
            if ($LastBackup -ne $null) {
                if (-not [string]::IsNullOrEmpty($LastBackup.Tag)) {
                    $LastBackup.Type = [PsBackupType]::Special
                } elseif ($_.Date.Year -gt $LastBackup.Date.Year) {
                    $LastBackup.Type = [PsBackupType]::Yearly
                } elseif ($_.Date.Month -gt $LastBackup.Date.Month) {
                    $LastBackup.Type = [PsBackupType]::Monthly
                } elseif ($_.Date.Day -gt $LastBackup.Date.Day) {
                    $LastBackup.Type = [PsBackupType]::Daily
                } else {
                    $LastBackup.Type = [PsBackupType]::Extra
                }
            }
            $LastBackup = $_
        }
        
        if ($PassThru) { $Backups | % { Write-Output $_ } }
    }
}

Pop-Location
