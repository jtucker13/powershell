#Sets shell folder to redirected managed desktop
#Written by Josh Tucker 9/17/2024
$shellfolderpath="HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
$desktoppath="C:\Desktop"
if(Test-Path $desktoppath){
    $value = Get-ItemPropertyValue -Path $shellfolderpath -Name "Desktop" -ErrorAction SilentlyContinue
    if($value -like $desktoppath){
        Write-Host "Shell folder already matches"
        Exit 0
    }
    else{
        Write-Host "Shell folder has different value"
        Exit 1
    }
}
else{
    Write-Host "Desktop path not found"
}
Exit 0