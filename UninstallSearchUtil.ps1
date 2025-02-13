param (
    [string]$DisplayName
)

# Define the registry paths
$registryPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
)

foreach ($registryPath in $registryPaths) {
    # Get the subkey that matches the display name using -like for partial matches
    $subkey = Get-ChildItem -Path $registryPath | Where-Object {
        try {
            (Get-ItemPropertyValue -Path $_.PSPath -Name "DisplayName") -like "*$DisplayName*"
        } catch {
            $false
        }
    }

    if ($subkey) {
        # Get the full display name, uninstall string, and GUID
        $fullDisplayName = Get-ItemPropertyValue -Path $subkey.PSPath -Name "DisplayName"
        $uninstallString = Get-ItemPropertyValue -Path $subkey.PSPath -Name "UninstallString"
        $guid = $subkey.PSChildName

        # Output the results
        [PSCustomObject]@{
            DisplayName    = $fullDisplayName
            UninstallString = $uninstallString
            GUID           = $guid
        }
        break
    }
}

if (-not $subkey) {
    Write-Output "No application found with the display name '$DisplayName'."
}