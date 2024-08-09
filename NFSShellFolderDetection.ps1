#Checks shell folders for the existence of an NFS path and exits if found
#Written by Josh Tucker 6/25/2024
$shellfolderpath="HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders"
$usershellmappings= @("Personal","My Pictures","My Music","My Videos","Favorites")
foreach($usm in $usershellmappings){
    $value = Get-ItemPropertyValue -Path $shellfolderpath -Name $usm -ErrorAction SilentlyContinue
    if($value -like '*\\*'){
        Write-Host "NFS drive detected in $usm shell folder"
        Exit 1
    }
}
Write-Host "No NFS drives detected in user shell mappings"
Exit 0