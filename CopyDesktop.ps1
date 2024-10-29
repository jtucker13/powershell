#Overrides system default permissions for a new C:\Desktop folder with a map of new permissions and copies a set of shortcuts
#Must be ran as system
#Written by Josh Tucker 10/24/2024
$directory="C:\Desktop"
#Map for desired permissions
$permissionmappings= @{
    "BUILTIN\Users"="ReadAndExecute, Synchronize"
    "NT AUTHORITY\Authenticated Users"="ReadAndExecute, Synchronize"
    "NT AUTHORITY\SYSTEM"="FullControl"
    "BUILTIN\Administrators"="FullControl"
}
New-Item -Path $directory -ItemType Directory -Force
$newacl = Get-Acl $directory
$newacl.SetAccessRuleProtection($true,$false) #Removes inherited rules from parent folder
#Loops through the map, creating an ACL rule for each service principal, enabling inheritance and adding to the acl object
foreach($kvp in $permissionmappings.GetEnumerator()){ 
    $newaclrule= New-Object System.Security.AccessControl.FileSystemAccessRule($kvp.Key, $kvp.Value, "ContainerInherit, ObjectInherit","None","Allow")
    $newacl.AddAccessRule($newaclrule)
}
Set-Acl $directory $newacl
#Done after setting ACLs so propagation flags aren't needed
Copy-Item -Path "$PSScriptRoot\StandardDesktop\*" -Destination $directory -Force