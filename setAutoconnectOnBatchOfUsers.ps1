param(
$numberOfAccounts,
[switch]$enableAutoConnect,
[switch]$verbose
)
$searchbase = "OU=Properties,DC=vdi,DC=vmware,DC=int"
$guids = Get-ADObject -server "localhost:389" -SearchBase $searchbase -Filter {(objectClass -eq "pae-Prop")} -Properties member,pae-NameValuePair -ResultSetSize $numberOfAccounts
foreach($guid in $guids){
    if($verbose){Write-Output $guid}
    if($enableAutoConnect){
        $sid = $guid.member.Split(",")[0].substring(3)
        Write-Host "Enabling autoconnect for $sid"
        Set-ADObject -Identity $guid -Remove @{'pae-NameValuePair'='alwaysConnect=false'} -Add @{'pae-NameValuePair'='alwaysConnect=true'}
        if($verbose){
            $newguid = Get-ADObject -server "localhost:389" -Identity $guid -Properties member,pae-NameValuePair
            Write-Output $newguid
        }
    }
}