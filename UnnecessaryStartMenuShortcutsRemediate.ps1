#Removes unwanted start menu shortcuts
#Written by Josh Tucker 9/5/2024
$shortcutpaths= @("Administrative Tools","Accessibility","Accessories","System Tools","Maintenance","Microsoft Intune Management Extension","Ivanti","Skype for Business.lnk")
foreach($name in $shortcutpaths){
    $path = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\"+$name
    if(Test-Path $path){
        Remove-Item $path -Recurse -Force
        Write-Host "$name shortcuts removed"
    }
    else{
        Write-Host "$name shortcuts not detected"
    }
}
Exit 0