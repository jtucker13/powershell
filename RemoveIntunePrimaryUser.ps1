#Utility for removing primary user from active device
#Pulled from https://github.com/rbalsleyMSFT/IntuneScripts/blob/main/ChangeIntunePrimaryUser/ChangeIntunePrimaryUser.ps1 and modified by Josh Tucker 3/14/2025

#Grabs secrets from environment variables if not specified
param(
    $clientId = $env:RemoveIntuneUserClientID,
    $clientSecret = $env:RemoveIntuneUserClientSecret,
    $tenantId = $env:RemoveIntuneUserTenantID,
    $CSVIn,
    $logFile
)

#Installs needed modules if not  present
if(-not (Get-PackageProvider Nuget -ListAvailable)){
    Install-PackageProvider Nuget -confirm:$false -Force
}
if(-not (Get-Module Microsoft.Graph -ListAvailable)){
    Install-Module Microsoft.Graph -confirm:$false -Force
}

### Helper function to handle logging
function Write-Log($message){
    if($logFile){
        $message|Out-File -FilePath $logFile -Append
    }
    else{
        Write-Output $message
    }
}
### Help function to grab access token
function Get-AccessToken {
    Write-Log 'Getting Access token'
    $tokenUrl = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"
    $body = @{
        grant_type = "client_credentials"
        client_id = $clientId
        client_secret = $clientSecret
        scope = "https://graph.microsoft.com/.default"
    }

    $response = Invoke-WebRequest -Method Post -Uri $tokenUrl -ContentType "application/x-www-form-urlencoded" -Body $body
    $accessToken = (ConvertFrom-Json $response.Content).access_token
    $expiresIn = (ConvertFrom-Json $response.Content).expires_in
    $expirationTime = (Get-Date).AddSeconds($expiresIn)
    Write-Log 'Successfully obtained access token'
    Write-Log "Access token expiration date and time: $expirationTime"
    $secureAccessToken = ConvertTo-SecureString $accessToken -AsPlainText -Force
    return $secureAccessToken
}

#Helper function to grab Entra device id, defaults to current device name if not specified
function Get-Device (){
    param(
        $accessToken,
        $devicename = $env:COMPUTERNAME
    )
    $uri = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?"+'$filter'+"=deviceName eq '" + $devicename + "'&" + '$select=id,deviceName,enrolledDateTime' 
    $headers = @{
        Authorization = "Bearer $accessToken"
        "Content-Type" = "application/json"
    }
    Write-Log "Searching for device $devicename"
    $devlist= (Invoke-MgGraphRequest -Method GET -Uri $uri -Headers $headers).value
    $device = $devlist|Sort-Object -Property enrolledDateTime -Descending|Select-Object -First 1
    Write-Log "Fetched device name $($device.deviceName) with device id of $($device.id)"
    return $device.id
}
<#
.SYNOPSIS
Removes primary user given a device id and auth token

.DESCRIPTION
Invokes post method to set userPrincipalName to null and performs a sync afterward

.PARAMETER accessToken
Token from helper script

.PARAMETER deviceId
GUID for Entra device
#>
function Remove-PrimaryUser ($accessToken, $deviceId) {
    $uri = "https://graph.microsoft.com/beta/deviceManagement/managedDevices/$deviceId/users/"+'$ref'
    #$syncuri = "https://graph.microsoft.com/beta/deviceManagement/managedDevices/$deviceId/microsoft.graph.syncDevice"
    $headers = @{
        Authorization = "Bearer $accessToken"
        "Content-Type" = "application/json"
    }
    Invoke-MgGraphRequest -Method DELETE -Uri $uri -Headers $headers
    Write-Log "Deleting primary user from device record"
    #Invoke-MgGraphRequest -Method POST -Uri $syncuri -Headers $headers
    #Write-Host "Syncing device"
}
#Main execution
$token = Get-AccessToken
Connect-MgGraph -AccessToken $token
if($CSVIn){
    $devices = Import-Csv $CSVIn
    foreach($dev in $devices){
        $device = Get-Device $token $dev.DeviceName
        Remove-PrimaryUser $token $device
    }
}
else{
    $device =Get-Device $token
    Remove-PrimaryUser $token $device
}

Disconnect-MgGraph
