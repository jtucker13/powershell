#Checks for the existence of unwanted UWP apps and exits if found
#Written by Josh Tucker 8/8/2024
$appnames= @("MicrosoftTeams","Microsoft.549981C3F5F10","Microsoft.Copilot","Microsoft.Windows.DevHome","Microsoft.BingWeather","Microsoft.ZuneMusic","Microsoft.GamingApp","Microsoft.XboxIdentityProvider","Microsoft.MicrosoftSolitaireCollection","Microsoft.Xbox.TCUI","Microsoft.XboxGameOverlay","Microsoft.WindowsCommunicationsApps","Microsoft.BingNews","Microsoft.ZuneVideo","Microsoft.FeedbackHub","Microsoft.GetHelp","Microsoft.XboxGamingOverlay","Microsoft.XBoxSpeechToTextOverlay","Microsoft.WindowsFeedbackHub","Microsoft.MixedReality.Portal","Microsoft.Getstarted","Microsoft.YourPhone","Microsoft.OneConnect")
foreach($name in $appnames){
    $app = Get-AppxPackage -Name $name -AllUsers
    $appprov = Get-AppxProvisionedPackage -Online|Where-Object{$_.DisplayName -eq $name}
    if($app){
        Write-Host "$name detected installed"
        $app|Remove-AppxPackage -AllUsers
    }
    else{
        Write-Host "$name not detected"
    }
    if($appprov){
        Write-Host "$name provisioning package installed"
        $appprov|Remove-AppxProvisionedPackage -Online
    }
    else{
        Write-Host "$name provisioning package not detected"
    }
}