#Takes an output from getHomeDrives.ps1 and determines if the homedrives are set to readonly
#Split into separate scripts to handle instances where multiple domains are in play which require different admin perms to check files
#Ballad Health
#Written by Josh Tucker 11/28/23
param(
    [Parameter(Mandatory)]$CSVIn, 
    [Parameter(Mandatory)]$CSVOut
    )
$cred = Get-Credential  
$users = Import-CSV $CSVIn  
$modusers = foreach($user in $users){
    [PSCustomObject]@{
        Name = $user.Name
        HomeDirectory = $user.HomeDirectory
        Email = $user.Email
        HomeDirectoryServer = $user.HomeDirectoryServer
        ReadOnly = (Get-ItemProperty $user.HomeDirectory -Credential $cred | Select-Object IsReadOnly)
    }
}
$modusers| Export-Csv -path $CSVOut