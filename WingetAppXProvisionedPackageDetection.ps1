# Define the package name for Winget
$packageName = "Microsoft.DesktopAppInstaller"

# Get the list of provisioned packages
$provisionedPackages = Get-AppxProvisionedPackage -Online

# Check if Winget is in the list of provisioned packages
$wingetProvisioned = $provisionedPackages | Where-Object { $_.DisplayName -eq $packageName }

if ($wingetProvisioned) {
    # Winget is provisioned for all users
    Write-Output "Winget is provisioned for all users."
    exit 0
} else {
    # Winget is not provisioned for all users
    exit 0
}

