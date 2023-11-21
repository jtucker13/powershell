#Used for migrating a device to a different OU and Imprivata type
#Ballad Health
#Written by Josh Tucker 10/6/23
#IN PROGRESS
param(
    [Parameter(Mandatory)]$Device, 
    [Parameter(Mandatory)]$DC,
    [Parameter(Mandatory)]$TargetOU, 
    $Log,
    [switch]$Type2UserCentric
)
Import-Module ActiveDirectory
$Cred = Get-Credential -Message "Enter admin credentials for modifying AD"
$RandoPass=[System.Web.Security.Membership]::GeneratePassword(10,2)
function MigrateOU{
    param(
        $device,
        $dc,
        $ou,
        $cred)
    #$Get-ADComputer $device | Move-ADObject -TargetPath $ou -Server $DC -Credential $cred
}
if($Type2UserCentric)
{
    Migrate-OU($Device,$DC,$TargetOU,$Cred)
}