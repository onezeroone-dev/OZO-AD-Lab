#Requires -RunAsAdministrator

# Start transcript
Start-Transcript -Path "C:\ProgramData\OZO AD Lab\specialize-synchronous.log"
# Install package provider
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
# Enable local Administrator account
& cmd.exe /c net user Administrator /active:yes
# Stop transcript
Stop-Transcript
# Restart computer
Restart-Computer -Force
