#Utility for modifying and working with CSPs
#Written by Josh Tucker 1/9/2025
param(
    $CSVIn, 
    [ValidateSet("CreateGroups","ExportGroupMembership","PromoteCSP")]$Action,
    $CSVOut,
    [bool]$mailEnabled=$false
    )
#Installs needed modules if not  present
if(-not (Get-PackageProvider Nuget -ListAvailable)){
    Install-PackageProvider Nuget -confirm:$false -Force
}
if(-not (Get-Module Microsoft.Graph -ListAvailable)){
    Install-Module Microsoft.Graph -confirm:$false -Force
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

if($Action -eq "CreateGroups"){
    if(!$CSVIn){
        $CSVIn=Get-CSVFile
    }
    $groupraw = Import-CSV $CSVIn 
    $groups=foreach($group in $groupraw){   
        $ng= New-MgGroup -DisplayName $group.DisplayName `
            -MailEnabled $mailEnabled `
            -MailNickname $group.MailNickname `
            -SecurityEnabled $true `
            -Description $group.Description
        [pscustomobject]@{
        DisplayName=$group.DisplayName
        MailNickname=$group.MailNickname
        Description=$group.Description
        Id=$ng.Id
        }
        Write-Host "Created group $($group.DisplayName) with id $($ng.Id)"
    }
    if($CSVOut){
        $groups|Export-CSV -Path $CSVOut -NoTypeInformation
    }
    else{
        $groups
    }
}
elseif($Action -eq "AddGroupMembers"){
    if(!$CSVIn){
        $CSVIn=Get-CSVFile
    }
    $assignraw=Import-CSV $CSVIn
    $assignments=foreach($assignment in $assignraw){
        $device = Get-MgDevice -Filter "displayName eq $assignment.GroupName"
    }
    #TODO
}