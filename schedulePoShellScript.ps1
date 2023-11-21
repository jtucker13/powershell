param(
[Parameter(Mandatory=$true)]$time,
[Parameter(Mandatory=$true)]$script,
$arguments,
[Parameter(Mandatory=$true)]$name,
[Parameter(Mandatory=$true)]$description
)
$action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument "-Execution Policy Bypass -WindowStyle Hidden -File $script $arguments"
$trigger =  New-ScheduledTaskTrigger -Daily -At $time
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName $name -Description $description