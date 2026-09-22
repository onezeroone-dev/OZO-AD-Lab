#Requires -RunAsAdministrator

If ([Boolean](Test-Path -Path "C:\ProgramData\OZO AD Lab\oobesystem-synchronous.log" -ErrorAction SilentlyContinue) -eq $false) {
    # First boot; start transcript
    Start-Transcript -Path "C:\ProgramData\OZO AD Lab\oobesystem-synchronous.log"
    # Import the ActiveDirectory and ADDSDeployment modules
    Import-Module ActiveDirectory
    Import-Module ADDSDeployment
    # Enable Remote Desktop
    Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "UserAuthentication" -Value 1
    # Disable new network window
    & cmd.exe /c reg add "HKLM\System\CurrentControlSet\Control\Network\NewNetworkWindowOff" /f
    # Install DSACL PowerShell module
    Install-Module -Name DSACL -Force
    # Install NTFSSecurity PowerShell module
    Install-Module -Name NTFSSecurity -Force
    # Install OZO PowerShell module
    Install-Module -Name OZO -Force
    # Install OZOAD PowerShell module
    Install-Module -Name OZOAD -Force
    # Install OZOLogger PowerShell module
    Install-Module -Name OZOLogger -Force
    # Install OZO Windows Event Log Provider setup script
    Install-Script -Name ozo-windows-event-log-provider-setup -Force
    # Run OZO Windows Event Log Provider setup script
    & "C:\Program Files\WindowsPowerShell\Scripts\ozo-windows-event-log-provider-setup.ps1"
    # Install the Active Directory Forest
    Install-ADDSForest -DomainName "contoso.com" -SafeModeAdministratorPassword (ConvertTo-SecureString -AsPlainText -String 'OZOADL@b$ecurePassw0rd' -Force) -DomainMode 7 -DomainNetbiosName "CONTOSO" -ForestMode 7 -InstallDns -NoRebootOnCompletion -Force
    # Schedule the run of the this script on the next login
    Register-ScheduledTask -TaskName "OZO AD Lab OOBE System Second Boot" -Trigger (New-ScheduledTaskTrigger -AtLogOn) -Action (New-ScheduledTaskAction -Execute "powerShell.exe" -Argument "-ExecutionPolicy Bypass -File 'C:\ProgramData\OZO AD Lab\oobesystem-synchronous.ps1'") -RunLevel Highest -Force
    # Stop transcript
    Stop-Transcript
    # Restart the computer
    Restart-Computer -Force
} Else {
    # Second boot; start transcript
    Start-Transcript -Path "C:\ProgramData\OZO AD Lab\oobesystem-synchronous.log" -Append
    # Import the ActiveDirectory module
    Import-Module ActiveDirectory
    # Add DNS server primary zone
    Add-DnsServerPrimaryZone -NetworkID "172.16.1.0/24" -ReplicationScope "Forest"
    # Add DHCP server in DC
    Add-DhcpServerInDC -DnsName "dc.contoso.com" -IPAddress "172.16.1.2"
    # Set DHCP Server v4 DNS settings
    Set-DhcpServerv4DnsSetting -ComputerName "dc.contoso.com" -DynamicUpdates "Always" -DeleteDnsRRonLeaseExpiry $True
    # Add a DHCP Server v4 scope
    Add-DhcpServerv4Scope -Name "Clients" -StartRange "172.16.1.1" -EndRange "172.16.1.254" -SubnetMask "255.255.255.0" -State Active
    # Add a DHCP Server v4 exclusion range
    Add-DhcpServerv4ExclusionRange -ScopeId "172.16.1.0" -StartRange "172.16.1.1" -EndRange "172.16.1.10"
    # Set DHCP Server v4 scope options
    Set-DhcpServerv4OptionValue -OptionID 3 -Value "172.16.1.1" -ScopeId "172.16.1.0" -ComputerName "dc.contoso.com"
    Set-DhcpServerv4OptionValue -DnsDomain "contoso.com" -DnsServer "172.16.1.2"
    # Add a Domain Groups OU
    New-ADOrganizationalUnit -Name "Domain Groups" -Path "DC=contoso,DC=com"
    # Add a Domain Users OU
    New-ADOrganizationalUnit -Name "Domain Users" -Path "DC=contoso,DC=com"
    # Move all default group objects to the Domain Groups OU
    Get-ADObject -Filter * -SearchBase "CN=Users,DC=contoso,DC=com" | Where-Object { $_.ObjectClass.ToLower() -eq "group" } | Move-ADObject -TargetPath "OU=Domain Groups,DC=contoso,DC=com"
    # Move all default user objects to the Domain Users OU
    Get-ADObject -Filter * -SearchBase "CN=Users,DC=contoso,DC=com" | Where-Object { $_.ObjectClass.ToLower() -eq "user" } | Move-ADObject -TargetPath "OU=Domain Users,DC=contoso,DC=com"
    # Create the Share folder
    New-Item -Path "C:\Share" -ItemType Directory -Force
    # Set ACL on the Share folder
    $acl = Get-Acl -Path "C:\Share"
    $acl.SetAccessRuleProtection($true,$true)
    Set-Acl -Path "C:\Share" -AclObject $acl
    # Import NTFSSecurity module
    Import-Module NTFSSecurity
    # Remove write NTFS permission for BuiltIn Users on the Share share
    Remove-NTFSAccess -Path "C:\Share" -Account "BUILTIN\Users" -AccessRights CreateDirectories
    Remove-NTFSAccess -Path "C:\Share" -Account "BUILTIN\Users" -AccessRights CreateFiles
    Remove-NTFSAccess -Path "C:\Share" -Account "BUILTIN\Users" -AccessRights ReadAndExecute
    # Add read permissions for Domain Users and write permissions Domain Administrators on the Share share
    Add-NTFSAccess -Path "C:\Share" -Account "CONTOSO\Domain Users" -AccessRights "ReadAndExecute" -AccessType "Allow" -AppliesTo "ThisFolderOnly"
    Add-NTFSAccess -Path "C:\Share" -Account "CONTOSO\Domain Admins" -AccessRights "FullControl" -AccessType "Allow" -AppliesTo "ThisFolderSubfoldersAndFiles"
    # Create the SMB share
    New-SmbShare -FolderEnumerationMode "AccessBased" -FullAccess "NT AUTHORITY\Authenticated Users" -Name "Share" -Path "C:\Share"
    # Unregister the second boot scheduled task
    Unregister-ScheduledTask -TaskName "OZO AD Lab OOBE System Second Boot" -Confirm:$false
    # Stop transcript
    Stop-Transcript
    # Restart the computer
    Restart-Computer -Force
}
