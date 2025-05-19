#Utility for modifying and working with groups and apps
#Modified by Josh Tucker 5/19/2025
#Note- Application assignments currently unable to fetch 365 apps or Windows store apps

param(
    $CSVIn, 
    [ValidateSet("CreateGroups","AddDeviceGroupMembers","GetDeviceGroupMembers","GetApplicationAssignments","SetApplicationAssignments")]$Action,
    $CSVOut,
    [bool]$mailEnabled=$false,
    $group,
    $application,
    $logFile,
    [switch]$verbose
    )
#Installs needed modules if not  present
if(-not (Get-PackageProvider Nuget -ListAvailable)){
    Install-PackageProvider Nuget -confirm:$false -Force
}
if(-not (Get-Module Microsoft.Graph -ListAvailable)){
    Install-Module Microsoft.Graph -confirm:$false -Force
}
Import-Module Microsoft.Graph.Devices.CorporateManagement
#Helper function to provide a GUI file picker for CSV if not specified
function Get-CSVFile{
    Add-Type -AssemblyName System.Windows.Forms
    $FilePicker = New-Object System.Windows.Forms.OpenFileDialog -Property @{
        Filter = "CSV Files (*.csv)|*.csv"
    }
    $FilePicker.ShowDialog()|Out-Null
    return $FilePicker.FileName
}
#Helper function for log files
function Write-Log($message){
    if($logFile){
        $message|Out-File -FilePath $logFile -Append
    }
    elseif($verbose){
        Write-Output $message
    }
}
#Helper function that builds the objects used for json conversion
function New-AssignmentNode{
    param(
        [ValidateSet("available","required","uninstall")]$intent,
        [ValidateSet("Included", "Excluded")]$assigntype,
        $groupId,
        [ValidateSet("foreground","background")]$doPriority="foreground",
        [ValidateSet("hideAll","showAll","showReboot")]$notifications="showReboot"
    )
    if($assigntype -eq "Excluded"){
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
            "deliveryOptimizationPriority" = $doPriority
        }
    }
    $assignmentbody = @{
        "@odata.type" = "#microsoft.graph.mobileAppAssignment"
        "intent"=$intent
        "settings"=$settings
        "target" = @{
            "@odata.type" = $targetodata
            "groupId" = $groupId
        }
        
    }
    return $assignmentbody
}
function Get-ApplicationAssignments{
    param(
        $applicationName
    )
    $appId = (Get-MgDeviceAppManagementMobileApp -Filter "DisplayName eq '$applicationName'").id
    Write-Log "Fetched application id $appId for $applicationName" 
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
            ApplicationName = $applicationName
            GroupName = (Get-MgGroup -GroupId $assignmentsplit[0]).DisplayName
            Intent = $assignment.Intent
            AssignmentType = $assignType
            }   
    }
    return $assignments
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
        Write-Log "Created group $($group.DisplayName) with id $($ng.Id)"
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
            $deviceid = ((Get-MgDevice -Filter "DisplayName eq '$($assignment.DeviceName)'")|Sort-Object -Property RegistrationDateTime -Descending|Select-Object -First 1).id
            $groupid = (Get-MgGroup -Filter "DisplayName eq '$($assignment.GroupName)'").id
            foreach($devid in $deviceid){
                New-MgGroupMember -GroupId $groupid -DirectoryObjectId $devid
            }
            
            Write-Log "Added $($assignment.DeviceName) to $($assignment.GroupName)"
        }
        catch {
            Write-Log "Failed to add $($assignment.DeviceName) to $($assignment.GroupName): $_"
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
    if($CSVIn){
        $applications=Import-CSV $CSVIn
        $assignmentArray=@()
        foreach($app in $applications){
            $appassignment = Get-ApplicationAssignments -applicationName $($app.ApplicationName)
            $assignmentArray += $appassignment
        }
        if($CSVOut){
            $assignmentArray|Export-CSV -Path $CSVOut
        }
        else{
            $assignmentArray
        }    
    }
    else{
        $appassignment =Get-ApplicationAssignments -applicationName $application
        if($CSVOut){
            $appassignment|Export-CSV -Path $CSVOut -NoTypeInformation
        }
        else{
            $appassignment
        }
    }    
}
elseif($Action -eq "SetApplicationAssignments"){
    if(!$CSVIn){
        $CSVIn=Get-CSVFile
    }
    $assignraw=Import-CSV $CSVIn
    $groupedassignments = $assignraw|Group-Object -Property ApplicationName
    foreach($app in $groupedassignments){
            $appId = (Get-MgDeviceAppManagementMobileApp -Filter "DisplayName eq '$($app.Name)'").id
            $assignmentArray=@()
            #Builds an object for each group assignment
            foreach ($row in $app.Group){
                $groupId = (Get-MgGroup -Filter "DisplayName eq '$($row.GroupName)'").id
                $assignment = New-AssignmentNode -intent $($row.Intent) -assigntype $($row.AssignmentType) -groupId $groupId
                $assignmentArray += $assignment
            } 
            $payload = @{
                mobileAppAssignments = $assignmentArray
            }
            $jsonPayload = $payload |ConvertTo-Json -Depth 5
            try {
                Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/v1.0/deviceAppManagement/mobileApps/$appId/assign" -Body $jsonPayload
                Write-Log "Updated assignments for $($app.Name) successfully"
            }
            catch {
                Write-Log "Failed to update assignments for $($app.Name)"
                Write-Log "JSON payload as follows:"
                Write-Log $jsonPayload
                <#Do this if a terminating exception happens#>
            }
        }
}
Disconnect-MgGraph