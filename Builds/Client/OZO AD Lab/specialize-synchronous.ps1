#Requires -RunAsAdministrator

<# Add User32 class for finding windows by class name
Add-Type @"
using System;
using System.Runtime.InteropServices;

public class User32 {
    [DllImport("user32.dll")]
    public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);
}
"@

# Wait for the desktop window to be available and for the Explorer process to be running
Do {
    Start-Sleep -Seconds 1
} Until ([User32]::FindWindow("Progman", $null) -eq [IntPtr]::Zero -And (Get-Process explorer -ErrorAction SilentlyContinue) -eq $true)
#>

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
