#Detects whether WU internet locations are blocked via policy/old regkeys, used for fixing issues with Company Portal installing
#Written by Josh Tucker 5/13/25
$shellfolderpath="HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
$value = Get-ItemPropertyValue -Path $shellfolderpath -Name "DoNotConnectToWindowsUpdateInternetLocation" -ErrorAction SilentlyContinue
if($value -eq 1){
    Write-Host "Internet WU locations are blocked"
    Exit 1
}
else{
    Write-Host "Internet WU locations available"
    Exit 0
}
