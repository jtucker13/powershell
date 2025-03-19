param (
    [string]$tenantId,
    [string]$clientId,
    [string]$clientSecret,
    [string]$sourcePath,
    [string]$userPrincipalName,
    $CSVIn
)

# Helper function to grab access token
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

# Function to get file metadata from OneDrive with error handling
function Get-OneDriveFileMetadata {
    param (
        [string]$accessToken,
        [string]$userPrincipalName
    )

    $headers = @{
        Authorization = "Bearer $accessToken"
    }

    $url = "https://graph.microsoft.com/v1.0/users/$userPrincipalName/drive/root/children"

    try {
        $response = Invoke-RestMethod -Method Get -Uri $url -Headers $headers
        $fileMetadata = @()
        foreach ($file in $response.value) {
            $relativePath = $file.parentReference.path -replace "^/drive/root:", ""
            $fileMetadata += [PSCustomObject]@{
                Path            = $relativePath + "/" + $file.name
                LastModified    = $file.lastModifiedDateTime
                SizeMB          = [math]::Round($file.size / 1MB, 2)
                Name            = $file.name
            }
        }
        return $fileMetadata
    } catch {
        Write-Error "Failed to retrieve OneDrive file metadata: $_"
        return @()
    }
}

# Function to get file metadata from on-premises folder
function Get-OnPremFileMetadata {
    param (
        [string]$sourcePath
    )

    $files = Get-ChildItem -Path $sourcePath -Recurse -File | Where-Object { $_.FullName -notmatch "\\Downloads\\" }
    $fileMetadata = @()

    foreach ($file in $files) {
        $relativePath = $file.FullName.Substring($sourcePath.Length).TrimStart("\")
        $fileMetadata += [PSCustomObject]@{
            Path            = $relativePath
            LastModified    = $file.LastWriteTime
            SizeMB          = [math]::Round($file.Length / 1MB, 2)
            Name            = $file.Name
        }
    }

    return $fileMetadata
}

# Function to compare file lists based on relative paths
function Compare-FileLists {
    param (
        [array]$listA,
        [array]$listB
    )

    $filesToCopy = @()

    foreach ($fileA in $listA) {
        $fileB = $listB | Where-Object { $_.Path -eq $fileA.Path }

        if (-not $fileB) {
            # File exists in directory A but not directory B
            $filesToCopy += $fileA
        } elseif ($fileA.LastModified -gt $fileB.LastModified) {
            # File exists in both locations but the file on A has a more recent modified date
            $filesToCopy += $fileA
        }
    }

    return $filesToCopy
}

# Function to copy files to OneDrive
function Copy-FilesToOneDrive {
    param (
        [array]$filesToCopy,
        [string]$accessToken,
        [string]$userPrincipalName
    )

    foreach ($file in $filesToCopy) {
        $relativePath = $file.Path
        $destinationUrl = "https://graph.microsoft.com/v1.0/users/$userPrincipalName/drive/root:/$relativePath/content"

        $fileContent = [System.IO.File]::ReadAllBytes($file.Path)
        $headers = @{
            Authorization = "Bearer $accessToken"
            "Content-Type"  = "application/octet-stream"
        }

        try {
            Invoke-RestMethod -Method Put -Uri $destinationUrl -Headers $headers -Body $fileContent
            Write-Output "Copied $($file.Name) to OneDrive."
        } catch {
            Write-Error "Failed to copy $($file.Name) to OneDrive: $_"
        }
    }
}
#Get token and connect to MGGraph
$accessToken = Get-AccessToken -tenantId $tenantId -clientId $clientId -clientSecret $clientSecret
Connect-MgGraph -AccessToken $token

if($CSVIn)
{
    $mappings=Import-CSV $CSVIn
    foreach($mapping in $mappings){
        # Get file metadata from on-premises folder (Directory A)
        $onPremFileMetadata = Get-OnPremFileMetadata -sourcePath $mapping.sourcePath
        # Get file metadata from OneDrive (Directory B)
        $oneDriveFileMetadata = Get-OneDriveFileMetadata -accessToken $accessToken -userPrincipalName $mapping.userPrincipalName
        # Compare file lists
        $filesToCopy = Compare-FileLists -listA $onPremFileMetadata -listB $oneDriveFileMetadata
        # Copy files to OneDrive
        Copy-FilesToOneDrive -filesToCopy $filesToCopy -accessToken $accessToken -userPrincipalName $mapping.userPrincipalName
    }
}
else{
    # Get file metadata from on-premises folder (Directory A)
    $onPremFileMetadata = Get-OnPremFileMetadata -sourcePath $sourcePath
    # Get file metadata from OneDrive (Directory B)
    $oneDriveFileMetadata = Get-OneDriveFileMetadata -accessToken $accessToken -userPrincipalName $userPrincipalName
    # Compare file lists
    $filesToCopy = Compare-FileLists -listA $onPremFileMetadata -listB $oneDriveFileMetadata
    # Copy files to OneDrive
    Copy-FilesToOneDrive -filesToCopy $filesToCopy -accessToken $accessToken -userPrincipalName $userPrincipalName
}

