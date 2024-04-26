#Accepts a CSV export of Imprivata login activity and parses according to selected switches
#Ballad Health
#Written by Josh Tucker 4/26/24
param(
    [Parameter(Mandatory)]$CSVIn,
    [switch]$GroupByUser,
    $MachinePattern,
    [ValidateSet("Shared Workstation Login","Secondary Session","Agent Login","Agent Unlock")]$ActivityType,
    $CSVOut
    )
$logins = Import-CSV $CSVIn 
if($MachinePattern){
    $logins = $logins|Where-Object{ $_.Host -like "$MachinePattern*" }
}
if($ActivityType){
    $logins = $logins|Where-Object{ $_.Activity -like $ActivityType }
}
if($GroupByUser)
{
    $groupedlogins=$logins|Group-Object -Property User
    $usefulData = foreach($groupedlogin in $groupedlogins)
    {
        [PSCustomObject]@{
        Name = $groupedlogin.Name
        Number = $groupedlogin.Count
        }   
    }
}
else{
    $usefulData = $logins
}
if($CSVOut){
    $usefulData|Export-CSV -Path $CSVOut
}
else{$usefulData} 