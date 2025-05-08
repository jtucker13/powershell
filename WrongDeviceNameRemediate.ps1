#Corrects Entra only devices which don't get correct naming convention during autopilot
#Written by Josh Tucker 5/1/2025
$deviceNamePrefix="W"
#Correct computer name based on appending prefix with serial number
$correctName = $deviceNamePrefix + (Get-WmiObject -Class Win32_BIOS).SerialNumber
#Compare and correct as needed
if ($env:COMPUTERNAME -ne $correctName) {
    $message = "Your computer name has been corrected to $correctName. Please restart your computer soon to finalize this process."
    Rename-Computer -NewName $correctName -Force
    msg.exe * $message
}