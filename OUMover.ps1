#Accepts a CSV with PC names and an argument for target OU and moves them accordingly
#Ballad Health
#Written by Josh Tucker 4/23/24
param(
    [Parameter(Mandatory)]$CSVIn,
    [Parameter(Mandatory)]$TargetOU,
    $log
    )
function Get-TimeStamp {    
    return "[{0:MM/dd/yy} {0:HH:mm:ss}]" -f (Get-Date)
}
    
if($log){Write-Output "$(Get-TimeStamp) Script started">>$log} 
Import-Module GroupPolicy
$PCsToMove = Import-CSV $CSVIn  
foreach($pc in $PCsToMove)
{
    $adpc=Get-ADComputer $pc.ComputerName
    $adpc|Move-ADObject -TargetPath $TargetOU
    if($log){Write-Output "$(Get-TimeStamp) Moved $($adpc.SamAccountName) from $($adpc.DistinguishedName) to $TargetOU">>$log}
} 