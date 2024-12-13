#Starts Windows store service and sets it to automatic
#Written by Josh Tucker 12/3/2024
$service="InstallService"
Get-Service $service|Set-Service -StartupType Manual -Status Running