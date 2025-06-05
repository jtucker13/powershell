$appxpath = "$PSScriptRoot\CompanyPortal-Universal-Production_x64.appx"
$dependencies = @(Get-ChildItem "$PSScriptRoot\Dependencies" -Filter "*.appx"|Select-Object -ExpandProperty FullName)
Add-AppxProvisionedPackage -Online -PackagePath $appxpath -SkipLicense -DependencyPackagePath $dependencies