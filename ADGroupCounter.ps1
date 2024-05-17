#Takes a CSV file with group names and outputs member count
#Ballad Health
#Written by Josh Tucker 11/28/23
param(
    [Parameter(Mandatory)]$CSVIn, 
    $CSVOut
    )  
$groups = Import-CSV $CSVIn  
$modgroups = foreach($group in $groups){
    [PSCustomObject]@{
        Name = $group.GroupName
        Count = @(Get-ADGroupMember -Identity $group.GroupName).count
    }
}
if($CSVOut){
    $modgroups|Export-CSV -Path $CSVOut
}
else{$modgroups}