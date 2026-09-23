#Requires -RunAsAdministrator

# Start transcript
Start-Transcript -Path "C:\ProgramData\OZO AD Lab\oobesystem-synchronous.log"
# Enable Remote Desktop
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "UserAuthentication" -Value 1
# Disable New Network Window
reg add "HKLM\System\CurrentControlSet\Control\Network\NewNetworkWindowOff" /f
# Install package provider
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
# Install features
Get-WindowsCapability -Name RSAT* -Online | Add-WindowsCapability -Online
# Install OZO PowerShell module
Install-Module OZO -Force
# Install OZOAD PowerShell module
Install-Module OZOAD -Force
# Install OZOLogger PowerShell module
Install-Module OZOLogger -Force
# Install OZO Windows Event Log Provider setup script
Install-Script ozo-windows-event-log-provider-setup -Force
# Run OZO Windows Event Log Provider setup script
& "C:\Program Files\WindowsPowerShell\Scripts\ozo-windows-event-log-provider-setup.ps1"
# Join to domain
Add-Computer -DomainName "contoso.com" -Credential (New-Object System.Management.Automation.PSCredential("Administrator", (ConvertTo-SecureString 'OZOADL@b$ecurePassw0rd' -AsPlainText -Force)))
# Stop transcript
Stop-Transcript
# Restart computer
Restart-Computer -Force
