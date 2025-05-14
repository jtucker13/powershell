$msixpath = "$PSScriptRoot\Microsoft.DesktopAppInstaller.msixbundle"
Add-AppxProvisionedPackage -Online -PackagePath $msixpath -SkipLicense