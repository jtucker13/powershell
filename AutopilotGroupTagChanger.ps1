#Utility for checking and modifying autopilot group tags en masse using msgraph
#Written by Josh Tucker 7/11/2024
param(
    $CSVIn, 
    [ValidateSet("SetGroupTags","GetDevices")]$Action,
    $CSVOut
    )
#Installs needed modules if not  present
if(-not (Get-PackageProvider Nuget -ListAvailable)){
    Install-PackageProvider Nuget -confirm:$false -Force
}
if(-not (Get-Module Microsoft.Graph -ListAvailable)){
    Install-Module Microsoft.Graph -confirm:$false -Force
}
if(-not (Get-Module WindowsAutopilotIntune -ListAvailable)){
    Install-Module WindowsAutopilotIntune -confirm:$false -Force
}
#Helper function to provide a GUI file picker for CSV if not specified
function Get-CSVFile{
    Add-Type -AssemblyName System.Windows.Forms
    $FilePicker = New-Object System.Windows.Forms.OpenFileDialog -Property @{
        Filter = "CSV Files (*.csv)|*.csv"
    }
    $FilePicker.ShowDialog()|Out-Null
    return $FilePicker.FileName
}
#Prompts user for sign in to Entra, requires mggraph permissions
Connect-MgGraph
if($Action -eq "SetGroupTags"){
    if(!$CSVIn){
        $CSVIn = Get-CSVFile
    }
    $devices = Import-CSV $CSVIn 
    foreach($device in $devices){
        try {
            $id = (Get-AutopilotDevice -serial $device.SerialNumber).id
            Set-AutoPilotDevice -id $id -groupTag "$($device.GroupTag)"
            Write-Host "Changed group tag to $($device.GroupTag) for serial number $($device.SerialNumber)"
        }
        catch {
            $message = $_.exception.$message
            Write-Host "$message on $($device.SerialNumber)"<#Do this if a terminating exception happens#>
        }
    }
    Invoke-AutopilotSync
}
if($Action -eq "GetDevices"){
    $devRaw = Get-AutoPilotDevice
    $devices = foreach($dev in $devRaw){
        [pscustomobject]@{
            SerialNumber=$dev.SerialNumber
            GroupTag=$dev.groupTag
            PurchaseOrder=$dev.purchaseOrderIdentifier
            Model=$dev.model
        }   
    }
    if($CSVOut){
        $devices|Export-CSV -Path $CSVOut -NoTypeInformation
    }
    else{
        $devices
        $devRaw
    }
}

Disconnect-MgGraph