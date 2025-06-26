#Removes an old scheduled task left over from Win 11 upgrade in place
#Written by Josh Tucker 6/26/2025

$task = Get-ScheduledTask -TaskName "PcaWallpaperAppDetect" -ErrorAction SilentlyContinue

if ($task) {
    $task|Unregister-ScheduledTask -Confirm:$false
}