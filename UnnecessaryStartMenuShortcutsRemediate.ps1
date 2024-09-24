#Removes unwanted start menu shortcuts
#Written by Josh Tucker 9/5/2024
$shortcutpaths= @("Windows Administrative Tools","Windows Ease of Access","Windows Accessories","Windows System","Microsoft Intune Management Extension","Ivanti")
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