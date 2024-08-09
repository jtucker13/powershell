#Powershell wrapper to output LMVUtil commands into a useful export
#Has to be ran on a Horizon connection server 
#Written by Josh Tucker 7/9/2024
param(
    $CSVOut,
    [Parameter(Mandatory)][ValidateSet("GetDesktops","GetApps","GetEntitlements")]$Action
    ) 

$usefulInfo = [System.Collections.ArrayList]@()
#Gets credentials, formats PW and does basic lmvutil calls
$cred=Get-Credential
$dRaw = lmvutil --authAs $cred.GetNetworkCredential().UserName --authDomain $cred.GetNetworkCredential().Domain --authPassword $cred.GetNetworkCredential().Password --listGlobalEntitlements
$aRaw = lmvutil --authAs $cred.GetNetworkCredential().UserName --authDomain $cred.GetNetworkCredential().Domain --authPassword $cred.GetNetworkCredential().Password --listGlobalApplicationEntitlements
#Parses through basic array known patterns, will need to update indexing if Horizon indexing changes in the future
$desktops=for($i=0;$i -lt $dRaw.Length;$i+=42){
    [pscustomobject]@{
        Name = $dRaw[$i].TrimEnd(':').TrimStart('Global entitlement ')
        Disabled = $dRaw[$i+8].TrimStart(' Disabled:')
        DefaultProtocol = $dRaw[$i+16].TrimStart(' Defaultprotocol:')
        HTMLAccess = $dRaw[$i+22].TrimStart(' HTMLAccess:')
    }    
}
$apps=for($i=0;$i -lt $aRaw.Length;$i+=40){
    [pscustomobject]@{
        Name = $aRaw[$i].TrimEnd(':').TrimStart('Global application entitlement ')
        Disabled = $aRaw[$i+6].TrimStart(' Disabled:')
        DefaultProtocol = $aRaw[$i+14].TrimStart(' Defaultprotocol:')
        HTMLAccess = $aRaw[$i+18].TrimStart(' HTMLAccess:')
    }     
}
#Forces lmvutil runs for each entitlement, so only fires if entitlements are being gathered. Creates objects for each group
if($Action -eq "GetEntitlements"){
    foreach($desktop in $desktops){
        $dentRaw = lmvutil --authAs $cred.GetNetworkCredential().UserName --authDomain $cred.GetNetworkCredential().Domain --authPassword $cred.GetNetworkCredential().Password --listEntitlements --entitlementName $desktop.Name
        for($i=0;$i -lt $dentRaw.Length;$i+=2){
            $listitem=[pscustomobject]@{
                Name = $desktop.Name
                Group = $dentRaw[$i].TrimStart('Group: ')
                Type = "Desktop"
            }
            $usefulInfo.Add($listitem)
        }
    }
    foreach($app in $apps){
        $aentRaw = lmvutil --authAs $cred.GetNetworkCredential().UserName --authDomain $cred.GetNetworkCredential().Domain --authPassword $cred.GetNetworkCredential().Password --listEntitlements --entitlementName $app.Name
        for($i=0;$i -lt $aentRaw.Length;$i+=2){
            $listitem=[pscustomobject]@{
                Name = $app.Name
                Group = $aentRaw[$i].TrimStart('Group: ')
                Type = "Application"
            }
            $usefulInfo.Add($listitem)
        }
    }
    if($CSVOut){
        $usefulInfo|Export-CSV -Path $CSVOut
    }
    else{
        $usefulInfo
    }
}
#Logic for outputting apps information only
elseif($Action -eq "GetApps"){
    if($CSVOut){
        $apps|Export-CSV -Path $CSVOut
    }
    else{
        $apps
    }
}
#Outputs desktops only if other options arent selected
else{
    if($CSVOut){
        $desktops|Export-CSV -Path $CSVOut -NoTypeInformation
    }
    else{
        $desktops
    }
}

