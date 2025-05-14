#Removes old regkey for blocking access to WU internet locations, used for fixing issues with Company Portal installing
#Written by Josh Tucker 5/13/25
$shellfolderpath="HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
Remove-ItemProperty -Path $shellfolderpath -Name "DoNotConnectToWindowsUpdateInternetLocation" -ErrorAction SilentlyContinue
