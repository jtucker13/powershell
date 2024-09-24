#Sets shell folder to redirected managed desktop
#Written by Josh Tucker 9/17/2024
$shellfolderpath="HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders"
$desktoppath="C:\Desktop"
if(Test-Path $desktoppath){
    Set-ItemProperty -Path $shellfolderpath -Name "Desktop" -Value $desktoppath
    Write-Host "Desktop redirected"
}
else{
    Write-Host "Desktop path not found"
}
Exit 0