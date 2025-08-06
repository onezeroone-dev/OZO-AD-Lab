# Declare variables
[SecureString] $encryptedLabPassword = (ConvertTo-SecureString -AsPlainText -String 'OZOADL@b$ecurePassw0rd' -Force)

If ((Test-Path -Path "C:\ProgramData\OZO AD Lab\transcript.txt") -eq $false) {
    # Start transcript
    Start-Transcript -Path "C:\ProgramData\OZO AD Lab\transcript.txt"
    # Import modules
    Import-Module ADDSDeployment
    # Set local Administrator password
    Set-LocalUser -Name "Administrator" -Password $encryptedLabPassword
    # Install contoso.com forest
    Install-ADDSForest -DomainName "contoso.com" -SafeModeAdministratorPassword $encryptedLabPassword -DomainMode 7 -DomainNetbiosName "CONTOSO" -ForestMode 7 -InstallDns -NoRebootOnCompletion -Force
    # Stop transcript
    Stop-Transcript
    # Restart
    Restart-Computer
}
