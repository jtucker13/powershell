#Checks whether Windows store service is running and returns 1 if not
#Written by Josh Tucker 12/3/2024
$service="InstallService"
$status = (Get-Service $service).Status
if($status -ne "Running"){
        Write-Host "$service not running"
        Exit 1
    }
else
{
    Write-Host "$service is running"
    Exit 0
}