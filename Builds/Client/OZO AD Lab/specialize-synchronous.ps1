# Start transcript
Start-Transcript -Path "C:\ProgramData\OZO AD Lab\specialize-synchronous.log"
# Install package provider
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
# Stop transcript
Stop-Transcript
