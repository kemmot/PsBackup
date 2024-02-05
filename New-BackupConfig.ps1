function New-BackupConfig() {
    $Config = [PsBackupConfig]::new()
    $Config.Name = "Backup_{0:yyyy-MM-dd_HHmmss}" -f (Get-Date)
    return $Config
}