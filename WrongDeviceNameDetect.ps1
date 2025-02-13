#Corrects Entra only devices which don't get correct naming convention during autopilot
#Written by Josh Tucker 1/16/2025
$deviceNamePrefix="W"
#Correct computer name based on appending prefix with serial number
$correctName = $deviceNamePrefix + (Get-WmiObject -Class Win32_BIOS).SerialNumber
#Compare and correct as needed
if ($env:COMPUTERNAME -ne $correctName) {
    Write-Host "Computer needs renamed"
        Exit 1
    }
else{
    Write-Host "Computer named correctly"
}
Exit 0


