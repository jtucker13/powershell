#Installs RSAT tools after a Windows Update
#Ballad Health
#Written by Josh Tucker 4/17/24
$libraries=@(
'Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0',
'Rsat.BitLocker.Recovery.Tools~~~~0.0.1.0',
'Rsat.CertificateServices.Tools~~~~0.0.1.0',
'Rsat.FileServices.Tools~~~~0.0.1.0',
'Rsat.GroupPolicy.Management.Tools~~~~0.0.1.0',
'Rsat.ServerManager.Tools~~~~0.0.1.0'
)
foreach($library in $libraries){
    Start-Process DISM.exe -ArgumentList "/Online /add-capability /CapabilityName $library"
}