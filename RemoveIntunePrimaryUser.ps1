#Utility for removing primary user from active device
#Pulled from https://github.com/rbalsleyMSFT/IntuneScripts/blob/main/ChangeIntunePrimaryUser/ChangeIntunePrimaryUser.ps1 and modified by Josh Tucker 3/14/2025

#Grabs secrets from environment variables if not specified
param(
    $clientId = $env:RemoveIntuneUserClientID,
    $clientSecret = $env:RemoveIntuneUserClientSecret,
    $tenantId = $env:RemoveIntuneUserTenantID
)

#Installs needed modules if not  present
if(-not (Get-PackageProvider Nuget -ListAvailable)){
    Install-PackageProvider Nuget -confirm:$false -Force
}
if(-not (Get-Module Microsoft.Graph -ListAvailable)){
    Install-Module Microsoft.Graph -confirm:$false -Force
}

### Helper function to grab access token
function Get-AccessToken {
    Write-Host 'Getting Access token'
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
    Write-Host 'Successfully obtained access token'
    Write-Host "Access token expiration date and time: $expirationTime"
    $secureAccessToken = ConvertTo-SecureString $accessToken -AsPlainText -Force
    return $secureAccessToken
}

#Helper function to grab current device id
function Get-Device ($accessToken){
    $uri = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?"+'$filter'+"=deviceName eq '" + $env:COMPUTERNAME + "'&" + '$select=id,deviceName' 
    $headers = @{
        Authorization = "Bearer $accessToken"
        "Content-Type" = "application/json"
    }
    Write-Host "Searching for device $env:COMPUTERNAME"
    $response= Invoke-MgGraphRequest -Method GET -Uri $uri -Headers $headers
    $id = $response.value[0].id
    $name = $response.value[0].deviceName
    Write-Host "Fetched device name $name with device id of $id"
    return $id
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
    Write-Host "Deleting primary user from device record"
    #Invoke-MgGraphRequest -Method POST -Uri $syncuri -Headers $headers
    #Write-Host "Syncing device"
}
#Main execution
$token = Get-AccessToken
Connect-MgGraph -AccessToken $token
$device =Get-Device $token
Remove-PrimaryUser $token $device
Disconnect-MgGraph
