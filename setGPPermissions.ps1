#Accepts a CSV with GPO names, domains, user groups, and permission levels and sets permissions according to the permission level
#Ballad Health
#Written by Josh Tucker 1/26/24
param(
    [Parameter(Mandatory)]$CSVIn,
    [switch]$Replace,
    $log
    )
function Get-TimeStamp {    
    return "[{0:MM/dd/yy} {0:HH:mm:ss}]" -f (Get-Date)
}
    
if($log){Write-Output "$(Get-TimeStamp) Script started">>$log} 
Import-Module GroupPolicy
$perms = Import-CSV $CSVIn  
foreach($perm in $perms)
{
    if($Replace){Set-GPPermission -DomainName $perm.Domain -Name $perm.GPOName -PermissionLevel $perm.PermissionLevel -TargetName $perm.GroupName -TargetType Group  -Replace}
    else{Set-GPPermission -DomainName $perm.Domain -Name $perm.GPOName -PermissionLevel $perm.PermissionLevel -TargetName $perm.GroupName -TargetType Group}
    if($log){Write-Output "$(Get-TimeStamp) Set GPO permissions to $($perm.PermissionLevel) for $($perm.GroupName) on $($perm.GPOName). Replace: $Replace">>$log}
} 