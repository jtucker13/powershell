#Queries AD for an output of the user's homedrive
#Ballad Health
#Written by Josh Tucker 11/21/23
param(
    [Parameter(Mandatory)]$searchbase
)
$users = Get-ADUser -Filter 'enabled -eq $true' -SearchBase $searchbase -Properties HomeDirectory | Select-Object SamAccountName, HomeDirectory, UserPrincipalName 
$modusers = foreach($user in $users){
    [PSCustomObject]
        Name = $user.SamAccountName
        HomeDirectory = $user.HomeDirectory
        Email = $user.UserPrincipalName
        HomeDirectoryServer = ($user.HomeDirectory.ToString().Split("\"))[2]
    }

$modusers| Export-Csv -path "c:\temp\userlist.csv"