#Queries the Horizon ADAM database for property settings that control autoconnect behavior. Has to be ran on a connection server inside the pod.
#Ballad Health
#Written by Josh Tucker 3/14/23

param(
$user, 
$domain, 
$log,
[switch]$allUsers,
[switch]$disableAutoconnect,
[switch]$verbose
)
if((!$user) -and (!$allUsers)){
    $user = Read-Host 'Input the user name'
}
if((!$domain) -and (!$allUsers)){
    $domain = Read-Host 'Input the domain name'
}
$usersid="ALL"
if(!$allUsers)
{
    $usersid = (Get-WmiObject -Class win32_userAccount -Filter "name='$user' and domain = '$domain'").SID
}
function Get-TimeStamp {
    
    return "[{0:MM/dd/yy} {0:HH:mm:ss}]" -f (Get-Date)
    
}
if($log){Write-Output "$(Get-TimeStamp) Script started">>$log}
$searchbase = "OU=Properties,DC=vdi,DC=vmware,DC=int"
$gotchas = Get-ADObject -server "localhost:389" -SearchBase $searchbase -Filter {(objectClass -eq "pae-Prop") -and (pae-NameValuePair -like '*alwaysConnect=true*')} -Properties member, pae-NameValuePair
foreach($gotcha in $gotchas)
{
    $sid = $gotcha.member.Split(",")[0].substring(3)
    if(($usersid -ne "ALL") -and ($sid -ne $usersid)){
        continue
    }
    if($verbose){
        echo $gotcha
        if($log){
            Write-Output "$(Get-TimeStamp) Found autoconnect" >> $log
            Write-Output $gotcha >> $log
            }
        }
    if($disableAutoconnect){
        Write-Host "Removing autoconnect for $sid"
        if($log){Write-Output "$(Get-TimeStamp) Removing autoconnect for $sid" >> $log}
        Set-ADObject -Identity $gotcha -Remove @{'pae-NameValuePair'='alwaysConnect=true'} -Add @{'pae-NameValuePair'='alwaysConnect=false'}
        if($verbose){
            $newgotcha = Get-ADObject -server "localhost:389" -Identity $gotcha -Properties member,pae-NameValuePair
            echo $newgotcha
            if($log){
            Write-Output "$(Get-TimeStamp) Modified GUID" >> $log
            Write-Output $newgotcha >> $log
            }
        }
    }
}
