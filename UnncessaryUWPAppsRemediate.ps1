#Checks for the existence of unwanted UWP apps and exits if found
#Written by Josh Tucker 8/8/2024
$appnames= @("Microsoft.Windows.DevHome","Microsoft.BingWeather","Microsoft.ZuneMusic","Microsoft.GamingApp","Microsoft.XboxIdentityProvider","Microsoft.MicrosoftSolitaireCollection","Microsoft.Xbox.TCUI","Microsoft.XboxGameOverlay",
"Microsoft.BingNews","Microsoft.ZuneVideo","Microsoft.FeedbackHub","Microsoft.GetHelp","Microsoft.XboxGamingOverlay","Microsoft.XBoxSpeechToTextOverlay","Microsoft.WindowsFeedbackHub","Microsoft.MixedReality.Portal","Microsoft.Getstarted","Microsoft.YourPhone")
foreach($name in $appnames){
    $app = Get-AppxPackage -Name $name -AllUsers
    if($app){
        Write-Host "$name detected installed"
        $app|Remove-AppxPackage -AllUsers
    }
    else{
        Write-Host "$name not detected"
    }
}