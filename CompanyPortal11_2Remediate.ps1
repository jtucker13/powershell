#Upgrades company portal to the latest and greatest using winget, installs winget as a prereq
#Written by Josh Tucker 3/24/2025

#Installs winget
Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe

#Uses winget to upgrade to latest and greatest, accepting EULA for msstore requiring country code
winget upgrade --name "Company Portal" --accept-package-agreements --accept-source-agreements