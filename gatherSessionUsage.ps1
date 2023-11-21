#Queries the Horizon ADAM database for applications, then gathers usage data from events historical database. Has to be ran on a connection server inside the pod.
#Ballad Health
#Written by Josh Tucker 6/11/23

param(
[Parameter(Mandatory)]$sqlServer, 
[Parameter(Mandatory)]$sqlUser, 
[Parameter(Mandatory)]$sqlPassword,
[Parameter(Mandatory)]$databaseName,
[Parameter(Mandatory)]$log,
$numberOfDays)
Import-Module SQLServer
$searchbase = "OU=Applications,DC=vdi,DC=vmware,DC=int"
#Fetch the application names
$applications = (Get-ADObject -server "localhost:389" -SearchBase $searchbase -Filter *).Name
foreach($application in $applications)
{
    $LaunchesQuery = "SELECT COUNT(ModuleAndEventText) AS TotalLaunches, COUNT(DISTINCT ModuleAndEventText) AS DistinctLaunches FROM $databaseName.[dbo].[event_historical] WHERE EventType = 'BROKER_APPLICATION_REQUEST' AND ModuleAndEventText like '%"+$application+"%'"
    if($numberOfDays)
    {
        $LaunchesQuery = $LaunchesQuery + " AND Time >= '"+$(Get-Date.AddDays(-($numberOfDays-1)) -Format "MM/dd/yyyy")+"'"
    }
    $result = Invoke-SQLCmd -ServerInstance "$sqlServer" -TrustServerCertificate -Database $databaseName -Username $sqlUser -Password $sqlPassword -Query $LaunchesQuery
    $totalLaunches = $result.TotalLaunches
    $distinctLaunches = $result.DistinctLaunches
    Write-Output "$(Get-Date -Format "MM/dd/yyyy"),$application,$totalLaunches,$distinctLaunches" >> $log
}
