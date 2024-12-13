#Checks shell folders for the existence of an NFS path and exits if found
#Written by Josh Tucker 6/25/2024
$shellfolderpath="HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
$usershellmappings= @("Personal","My Pictures","My Music","My Videos","Favorites","{374DE290-123F-4565-9164-39C4925E467B}","{F42EE2D3-909F-4907-8871-4C22FC0BF756}","{0DDD015D-B06C-45D5-8C4C-F59713854639}","{A0C69A99-21C8-4671-8703-7934162FCF1D}","{35286A68-3C57-41A1-BBB1-0EAE73D76C95}","{7D83EE9B-2244-4E70-B1F5-5393042AF1E4}")
foreach($usm in $usershellmappings){
    $value = Get-ItemPropertyValue -Path $shellfolderpath -Name $usm -ErrorAction SilentlyContinue
    if($value -like '*\\*'){
        Write-Host "NFS drive detected in $usm shell folder"
        Exit 1
    }
}
Write-Host "No NFS drives detected in user shell mappings"
Exit 0