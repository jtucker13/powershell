$targetVersion=[Version]"64.26100.13.16779"
$driverdetails=Get-WmiObject Win32_PnPSignedDriver | Where-Object { $_.DeviceClass -eq "CAMERA" -and $_.Manufacturer -match "Intel" } | Select-Object DeviceName, Manufacturer, DeviceClass, DriverVersion
$driverVersion=[Version]$driverdetails.DriverVersion
if($driverVersion -ge $targetVersion){
    Write-Host "Driver is currently on $driverVersion, no updates needed"
    Exit 0
}
else{
    Write-Host "Driver is currently on $driverVersion, needs update"
    Exit 1
}
