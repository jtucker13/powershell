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
#Function to compare file lists and populate filesToCopy
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
            Write-Host "Marking $($fileA.Name) ($($fileA.SizeMB) MB) for copy."
            $filesToCopy += $fileA
        } elseif ($fileA.LastModified -gt $fileB.LastModified) {
            # File exists in both locations but the file on A has a more recent modified date
            Write-Host "Marking $($fileA.Name) ($($fileA.SizeMB) MB) for copy."
            $filesToCopy += $fileA
        }
    }

    return $filesToCopy
}

# Function to create an upload session
function Create-UploadSession {
    param (
        [string]$accessToken,
        [string]$userPrincipalName,
        [string]$relativePath
    )

    $headers = @{
        Authorization = "Bearer $accessToken"
        "Content-Type"  = "application/json"
    }

    $body = @{
        item = @{
            "@microsoft.graph.conflictBehavior" = "replace"
            name = [System.IO.Path]::GetFileName($relativePath)
        }
    } | ConvertTo-Json

    $url = "https://graph.microsoft.com/v1.0/users/$userPrincipalName/drive/root:/$relativePath/createUploadSession"
    $response = Invoke-RestMethod -Method Post -Uri $url -Headers $headers -Body $body
    return $response.uploadUrl
}

# Function to upload file in chunks
function Upload-FileInChunks {
    param (
        [string]$uploadUrl,
        [string]$filePath
    )

    $chunkSize = 60MB
    $fileSize = (Get-Item $filePath).Length
    $fileStream = [System.IO.File]::OpenRead($filePath)
    $buffer = New-Object byte[] $chunkSize
    $bytesRead = 0
    $start = 0

    while ($bytesRead -lt $fileSize) {
        $end = [math]::Min($start + $chunkSize, $fileSize) - 1
        $length = $end - $start + 1
        $fileStream.Read($buffer, 0, $length) | Out-Null

        $headers = @{
            "Content-Length" = $length
            "Content-Range"  = "bytes $start-$end/$fileSize"
        }

        $body = [System.IO.MemoryStream]::new()
        $body.Write($buffer, 0, $length)
        $body.Seek(0, [System.IO.SeekOrigin]::Begin) | Out-Null

        Invoke-RestMethod -Method Put -Uri $uploadUrl -Headers $headers -Body $body

        $start += $chunkSize
    }

    $fileStream.Close()
}

# Function to upload small files
function Upload-SmallFile {
    param (
        [string]$accessToken,
        [string]$userPrincipalName,
        [string]$relativePath,
        [string]$filePath
    )

    $destinationUrl = "https://graph.microsoft.com/v1.0/users/$userPrincipalName/drive/root:/$relativePath/content"
    $fileContent = [System.IO.File]::ReadAllBytes($filePath)
    $headers = @{
        Authorization = "Bearer $accessToken"
        "Content-Type"  = "application/octet-stream"
    }

    Invoke-RestMethod -Method Put -Uri $destinationUrl -Headers $headers -Body $fileContent
}

# Function to copy files to OneDrive using appropriate method based on file size
function Copy-FilesToOneDrive {
    param (
        [array]$filesToCopy,
        [string]$accessToken,
        [string]$userPrincipalName
    )

    foreach ($file in $filesToCopy) {
        $relativePath = $file.Path
        if ($file.SizeMB -le 4) {
            try {
                Upload-SmallFile -accessToken $accessToken -userPrincipalName $userPrincipalName -relativePath $relativePath -filePath $file.Path
                Write-Host "Copied $($file.Name) to $relativePath using simple upload."
            } catch {
                Write-Error "Failed to copy $($file.Name) to OneDrive using simple upload: $_"
            }
        } else {
            $uploadUrl = Create-UploadSession -accessToken $accessToken -userPrincipalName $userPrincipalName -relativePath $relativePath
            try {
                Upload-FileInChunks -uploadUrl $uploadUrl -filePath $file.Path
                Write-Host "Copied $($file.Name) to $relativePath using upload session."
            } catch {
                Write-Error "Failed to copy $($file.Name) to OneDrive using upload session: $_"
            }
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

