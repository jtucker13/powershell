#Detects whether an old scheduled task is left over from Win 11 upgrade in place
#Written by Josh Tucker 6/26/2025

$task = Get-ScheduledTask -TaskName "PcaWallpaperAppDetect" -ErrorAction SilentlyContinue

if ($task) {
    Write-Output "Detected"
    exit 1
} else {
    Write-Output "Not Detected"
    exit 0
}
