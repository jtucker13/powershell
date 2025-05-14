#Utility for modifying and working with CSPs
#Written by Josh Tucker 1/9/2025
param(
    $CSVIn, 
    [ValidateSet("CreateGroups","AddDeviceGroupMembers","GetDeviceGroupMembers","GetApplicationAssignments","AddApplicationAssignments")]$Action,
    $CSVOut,
    [bool]$mailEnabled=$false,
    $group,
    $application,
    [ValidateSet("Available","Required","Uninstall")]$intent,
    [ValidateSet("Included, Excluded")]$assigntype
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
elseif($Action -eq "AddDeviceGroupMembers"){
    if(!$CSVIn){
        $CSVIn=Get-CSVFile
    }
    $assignraw=Import-CSV $CSVIn
    $assignments=foreach($assignment in $assignraw){
        try {
            $deviceid = (Get-MgDevice -Filter "DisplayName eq '$($assignment.DeviceName)'").id
            $groupid = (Get-MgGroup -Filter "DisplayName eq '$($assignment.GroupName)'").id
            foreach($devid in $deviceid){
                New-MgGroupMember -GroupId $groupid -DirectoryObjectId $devid
            }
            
            Write-Host "Added $($assignment.DeviceName) to $($assignment.GroupName)"
        }
        catch {
            Write-Error "Failed to add $($assignment.DeviceName) to $($assignment.GroupName): $_"
        }
        
    }
    #TODO
}
elseif($Action -eq "GetDeviceGroupMembers"){
    $groupid = (Get-MgGroup -Filter "DisplayName eq '$group'").id
    $assignraw= Get-MgGroupMember -GroupId $groupid
    $assignments=foreach($assignment in $assignraw){
        [PSCustomObject]@{
            DeviceName = (Get-MgDevice -DeviceId $assignment.id).DisplayName
            GroupName = $group
            }   
    }
    if($CSVOut){
        $assignments|Export-CSV -Path $CSVOut
    }
    else{
        $assignments
    } 
}
elseif($Action -eq "GetApplicationAssignments"){
    $appId = (Get-MgApplication -Filter "DisplayName eq '$application'").id 
    $assignraw= (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/deviceAppManagement/mobileApps/$appId/assignments").value
    $assignments=foreach($assignment in $assignraw){
        $assignmentsplit = $($assignment.id) -split "_"
        if($assignmentsplit[2] -eq 0){
            $assignType = "Included"
        }
        else{
            $assignType = "Excluded"
        }
        [PSCustomObject]@{
            ApplicationName = $application
            GroupName = (Get-MgGroup -GroupId $assignmentsplit[0]).DisplayName
            Intent = $assignment.Intent
            AssignmentType = $assignType
            }   
    }
    if($CSVOut){
        $assignments|Export-CSV -Path $CSVOut
    }
    else{
        $assignments
    }    
}
elseif($Action -eq "AddApplicationAssignments"){
    if($CSVIn){

    }
    else{

    }
    $appId = (Get-MgApplication -Filter "DisplayName eq '$application'").id
    $groupid = (Get-MgGroup -Filter "DisplayName eq '$group'").id
    if($assigntype = "Excluded"){
        $targetodata="#microsoft.graph.exclusionGroupAssignmentTarget"
        $settings=$null
    }
    else{
        $targetodata="#microsoft.graph.groupAssignmentTarget"
        $settings = @{
            "@odata.type"                  = "#microsoft.graph.win32LobAppAssignmentSettings"
            "notifications"                = "hideAll"
            "restartSettings"              = $null
            "installTimeSettings"          = $null
            "deliveryOptimizationPriority" = "foreground"
        }
    }
    $assignmentbody = @{
        "@odata.type" = "#microsoft.graph.MobileAppAssignment"
        "target" = @{
            "@odata.type" = $targetodata
            "groupId" = $groupId
        }
        "intent"=$intent
        "settings"=$settings
    } 
    Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/v1.0/deviceAppManagement/mobileApps/$appId/assign" -Body ($assignmentbody | ConvertTo-Json)
   
}
Disconnect-MgGraph