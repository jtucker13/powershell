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