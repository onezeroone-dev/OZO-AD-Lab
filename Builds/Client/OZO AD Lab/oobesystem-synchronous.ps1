#Requires -Modules ActiveDirectory -RunAsAdministrator

# SCRIPTBLOCKS
[ScriptBlock] $setNTFSPermissions = {
    # Import NTFSSecurity module
    Import-Module NTFSSecurity
    # Remove write NTFS permission for BuiltIn Users on the Share share
    Remove-NTFSAccess -Path "C:\Share" -Account "BUILTIN\Users" -AccessRights CreateDirectories; Remove-NTFSAccess -Path "C:\Share" -Account "BUILTIN\Users" -AccessRights CreateFiles
    Remove-NTFSAccess -Path "C:\Share" -Account "BUILTIN\Users" -AccessRights ReadAndExecute
    # Add read permissions for Domain Users and write permissions Domain Administrators on the Share share
    Add-NTFSAccess -Path "C:\Share" -Account "CONTOSO\Domain Users" -AccessRights ReadAndExecute -AccessType Allow -AppliesTo ThisFolderOnly
    Add-NTFSAccess -Path "C:\Share" -Account "CONTOSO\Domain Administrators" -AccessRights FullControl -AccessType Allow -AppliesTo ThisFolderSubfoldersAndFiles
}

# Start transcript
Start-Transcript -Path "C:\ProgramData\OZO AD Lab\oobesystem-synchronous.log" -Force
# Enable Remote Desktop
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "UserAuthentication" -Value 1
# Disable New Network Window
reg add "HKLM\System\CurrentControlSet\Control\Network\NewNetworkWindowOff" /f
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
# Add a Domain Groups OU
New-ADOrganizationalUnit -Name "Domain Groups" -Path "DC=contoso,DC=com"
# Add a Domain Users OU
New-ADOrganizationalUnit -Name "Domain Users" -Path "DC=contoso,DC=com"
# Move all default group objects to the Domain Groups OU
Get-ADObject -Filter * -SearchBase "CN=Users,DC=contoso,DC=com" | Where-Object { $_.ObjectClass.ToLower() -eq "group" } | Move-ADObject -TargetPath "OU=Domain Groups,DC=contoso,DC=com"
# Move all default user objects to the Domain Users OU
Get-ADObject -Filter * -SearchBase "CN=Users,DC=contoso,DC=com" | Where-Object { $_.ObjectClass.ToLower() -eq "user" } | Move-ADObject -TargetPath "OU=Domain Users,DC=contoso,DC=com"
# Set NTFS permissions on the Share folder on the DC
Invoke-Command -ComputerName "dc.contoso.com" -ScriptBlock $setNTFSPermissions
# Stop transcript
Stop-Transcript
