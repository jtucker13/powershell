# Define the package name for Winget
$packageName = "Microsoft.CompanyPortal"

# Check if Winget is installed
$companyportalProvisioned = Get-AppxPackage -Name $packageName

if ($companyportalProvisioned) {
    winget upgrade --name "Company Portal" --accept-package-agreements --accept-source-agreements
} else {
    winget install --name "Company Portal" --accept-package-agreements --accept-source-agreements
}

