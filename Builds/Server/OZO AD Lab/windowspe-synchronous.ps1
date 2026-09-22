# Start transcript
Start-Transcript -Path "C:\ProgramData\OZO AD Lab\windowspe-synchronous.log" -Force
# Configure the Ethernet adapter
New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress "172.16.1.2" -PrefixLength 24 -DefaultGateway "172.16.1.1"
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses "1.1.1.1"
Set-DnsClientGlobalSetting -SuffixSearchList "contoso.com"
# Install package provider
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
# Install Active Directory Domain Services (ADDS)
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
# Install DHCP server
Install-WindowsFeature DHCP -IncludeManagementTools
# Add DHCP security groups
& netsh dhcp add securitygroups
# Install DFS
Install-WindowsFeature FS-DFS-Replication -IncludeManagementTools
# Install File Server Resource Manager
Install-WindowsFeature FS-Resource-Manager -IncludeManagementTools
# Install the Remote Server Administration Tools (RSAT-ADDS and RSAT-ADLDS)
Install-WindowsFeature -Name "RSAT-ADDS","RSAT-ADLDS"
# Stop transcript
Stop-Transcript
