# Start transcript
Start-Transcript -Path "C:\ProgramData\OZO AD Lab\specialize-synchronous.log"
# Install package provider
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
# Set Execution Policy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine -Force -ErrorAction SilentlyContinue
# Enable local Administrator account
& cmd.exe /c net user Administrator /active:yes
# Stop transcript
Stop-Transcript
