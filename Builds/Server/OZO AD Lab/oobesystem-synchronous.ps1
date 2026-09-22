#Requires -Modules ActiveDirectory,ADDSDeployment -RunAsAdministrator

# Start transcript
Start-Transcript -Path "C:\ProgramData\OZO AD Lab\oobesystem-synchronous.log" -Force
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
# Create the Share folder
New-Item -Path "C:\Share" -ItemType Directory -Force
# Set ACL on the Share folder
$acl = Get-Acl -Path "C:\Share"
$acl.SetAccessRuleProtection($true,$true)
Set-Acl -Path "C:\Share" -AclObject $acl
# Create the SMB share
New-SmbShare -FolderEnumerationMode "AccessBased" -FullAccess "NT AUTHORITY\Authenticated Users" -Name "Share" -Path "C:\Share"
# Install the Active Directory Forest
Install-ADDSForest -DomainName "contoso.com" -SafeModeAdministratorPassword (ConvertTo-SecureString -AsPlainText -String 'OZOADL@b$ecurePassw0rd' -Force) -DomainMode 7 -DomainNetbiosName "CONTOSO" -ForestMode 7 -InstallDns -NoRebootOnCompletion -Force
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
# Stop transcript
Stop-Transcript
