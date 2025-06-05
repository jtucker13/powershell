$msixpath = "$PSScriptRoot\AppInstaller_x64.msix"
$licensepath = "$PSScriptRoot\e53e159d00e04f729cc2180cffd1c02e_License1.xml"
$dependencies = @(Get-ChildItem $PSScriptRoot -Filter "*.appx"|Select-Object -ExpandProperty FullName)
Add-AppxProvisionedPackage -Online -PackagePath $msixpath -LicensePath $licensepath -DependencyPackagePath $dependencies
