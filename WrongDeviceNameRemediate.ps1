#Corrects Entra only devices which don't get correct naming convention during autopilot
#Written by Josh Tucker 1/16/2025
$deviceNamePrefix="W"
#Correct computer name based on appending prefix with serial number
$correctName = $deviceNamePrefix + (Get-WmiObject -Class Win32_BIOS).SerialNumber
#Compare and correct as needed
if ($env:COMPUTERNAME -ne $correctName) {
    Add-Type -AssemblyName System.Windows.Forms
    $message = "Your computer name has been corrected and your PC needs to be restarted. Select Yes to restart now, or No to restart later"
    $title = "Ballad Rename Script"
    $buttons = [System.Windows.Forms.MessageBoxButtons]::YesNo
    $icon = [System.Windows.Forms.MessageBoxIcon]::Warning
    $result = [System.Windows.Forms.MessageBox]::Show($message, $title, $buttons, $icon)
    if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
        Rename-Computer -NewName $correctName -Force -Restart
    }
     else {
        Rename-Computer -NewName $correctName -Force
    }
}