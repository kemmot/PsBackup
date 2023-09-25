function New-BackupConfig() {
    $Config = [PsBackupConfig]::new()
    $Config.Name = "{0:yyyy-MM-dd_HHmmss}" -f (Get-Date)
    return $Config
}