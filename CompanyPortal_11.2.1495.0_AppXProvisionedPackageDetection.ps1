# Define the package name for Company Portal
$packageName = "Microsoft.CompanyPortal"

# Get the list of provisioned packages
$provisionedPackages = Get-AppxProvisionedPackage -Online

# Check if Company Portal is in the list of provisioned packages
$companyportalProvisioned = $provisionedPackages | Where-Object { $_.DisplayName -eq $packageName }

if ($companyportalProvisioned) {
    # Company Portal is provisioned for all users
    Write-Output "Company Portal is provisioned for all users."
    exit 0
} else {
    # Company Portal is not provisioned for all users
    exit 0
}