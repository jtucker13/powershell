#Takes an output from getHomeDrives.ps1 and checks last access time
#Split into separate scripts to handle instances where multiple domains are in play which require different admin perms to check files
#Ballad Health
#Written by Josh Tucker 11/28/23
param(
    [Parameter(Mandatory)]$CSVIn, 
    [Parameter(Mandatory)]$CSVOut
    )  
$users = Import-CSV $CSVIn  
$modusers = foreach($user in $users){
    [PSCustomObject]@{
        Name = $user.Name
        HomeDirectory = $user.HomeDirectory
        Email = $user.Email
        HomeDirectoryServer = $user.HomeDirectoryServer
        LastWriteTime = (Get-ItemProperty $user.HomeDirectory).LastWriteTime
    }
}
$modusers| Export-Csv -path $CSVOut