#Checks for the existence of unwanted shortcut directories and returns 1 if any are found
#Written by Josh Tucker 9/5/2024
$shortcutpaths= @("Administrative Tools","Accessibility","Accessories","System Tools","Maintenance","Microsoft Intune Management Extension","Ivanti","Skype for Business.lnk")
foreach($name in $shortcutpaths){
    $path = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\"+$name
    if(Test-Path $path){
        Write-Host "$name shortcuts detected"
        Exit 1
    }
    else{
        Write-Host "$name shortcuts not detected"
    }
}
Exit 0