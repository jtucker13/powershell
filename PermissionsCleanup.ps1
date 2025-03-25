#Removes full control and cleans up rights for a specified user and directory
#Users must be formatted as DOMAIN\username
#Written by Josh Tucker 3/25/2025
param(
    $NTuser,
    $NTdirectory,
    $CSVIn
)
#Set as a function to better facilitate looping
function RemoveWriteAccessForUser($user,$directory){
    $newacl = Get-Acl $directory
    $accessrules = $newacl.Access
    #Loops through the access rules, finding each entry for the user and removing it
    foreach($rule in $accessrules){
        if($rule.IdentityReference.Value -eq $user){
            $newacl.RemoveAccessRule($rule)
            Write-Host "$($rule.FileSystemRights) removed for $user" 
        }
    }
    #Readds ReadAndExecute/Synchronize rights
    $newaclrule= New-Object System.Security.AccessControl.FileSystemAccessRule($user, "ReadAndExecute, Synchronize", "ContainerInherit, ObjectInherit","None","Allow")
    $newacl.AddAccessRule($newaclrule)
    Write-Host "Read only access restored for $user"
    Set-Acl $directory $newacl
}

#Main script execution
if($CSVIn){
    $mappings=Import-Csv $CSVIn
    foreach($map in $mappings){
        RemoveWriteAccessForUser -user $mapping.User -directory $mapping.Directory
    }
}
else{
    RemoveWriteAccessForUser -user $NTuser -directory $NTdirectory
}