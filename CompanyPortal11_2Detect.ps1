#Detects if company portal is out of date
#Written by Josh Tucker 3/24/25
$cp = Get-AppxPackage -Name "Microsoft.CompanyPortal" | Select-Object -Property Name, Version
$cpversion = [Version]$cp.Version
$targetversion = [Version]"11.2"
#Compare and correct as needed
if ($cpversion -lt $targetversion) {
    Write-Host "Company portal needs update"
        Exit 1
    }
else{
    Write-Host "Company portal is up to date"
}
Exit 0


