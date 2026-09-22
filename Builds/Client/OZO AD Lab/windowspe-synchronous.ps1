# Start transcript
Start-Transcript -Path "C:\ProgramData\OZO AD Lab\windowspe-synchronous.log" -Force
# Install package provider
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
# Install features
Get-WindowsCapability -Name RSAT* -Online | Add-WindowsCapability -Online
# Enable local administrator account
& cmd.exe /c net user Administrator /active:yes
# Stop transcript
Stop-Transcript
