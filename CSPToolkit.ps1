#Utility for modifying and working with CSPs
#Written by Josh Tucker 1/9/2025
param(
    $CSVIn, 
    [ValidateSet("BackupCSP","DuplicateCSP","PromoteCSP")]$Action,
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

if($Action -eq "BackupCSP"){
    #TODO
}