#Accepts a CSV with device names and outputs DNS resolution
#Ballad Health
#Written by Josh Tucker 4/26/24
param(
    [Parameter(Mandatory)]$CSVIn,
    [switch]$DNSOnly,
    $Server,
    $CSVOut
    )
$usefulInfo = [System.Collections.ArrayList]@()
$devices = Import-CSV $CSVIn  
foreach($device in $devices)
{
    if($DNSOnly -And $Server){
        $record = Resolve-DnsName -Name $device.Hostname -DnsOnly -Server $Server|Where-Object{ $_.Section -eq 'Answer' }
    }
    elseif($DNSOnly){
        $record = Resolve-DnsName -Name $device.Hostname -DnsOnly|Where-Object{ $_.Section -eq 'Answer' }
    }
    elseif($Server){
        $record = Resolve-DnsName -Name $device.Hostname -Server $Server|Where-Object{ $_.Section -eq 'Answer' }
    }
    else{
        $record = Resolve-DnsName -Name $device.Hostname|Where-Object{ $_.Section -eq 'Answer' }
    }
    if($record.Name){
        $listitem=[PSCustomObject]@{
            Name = $record.Name
            Found = "True"
            Type = $record.Type
            IP = $record.IPAddress
        }
        $usefulInfo.Add($listitem)
    }
    else{
        $listitem=[PSCustomObject]@{
            Name = $device.Hostname
            Found = "False"
            Type = ""
            IP = ""
        }
        $usefulInfo.Add($listitem)
    }
}
if($CSVOut){
    $usefulInfo|Export-CSV -Path $CSVOut
}
else{$usefulInfo} 