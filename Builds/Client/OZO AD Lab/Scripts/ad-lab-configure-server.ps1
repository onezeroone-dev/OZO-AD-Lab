# VARIABLES
[Array]  $units = @("Administration","IT","Development","Finance","Human Resources","Marketing","Operations")
[String] $dcIP = "172.16.1.2"
[String] $installationIP = "172.16.1.100"
[String] $ipAddress = "172.16.1.3"
[String] $sharePath = "C:\Share"

# SCRIPTBLOCKS
# Add DNS record
$configureDNS = {
    Add-DnsServerResourceRecordA -CreatePtr -Name "server" -IPv4Address $ipAddress -ZoneName "contoso.com"
}
# Add new IP address
$addNewIPAddress = {
    # Update the Ethernet IP address
    New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress $ipAddress -PrefixLength 24 -DefaultGateway "172.16.1.1"
    Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses "172.16.1.2"
}
$installFeatures = {
    # Install the DHCP server
    Install-WindowsFeature FS-Resource-Manager -IncludeManagementTools
}
# Install package providers
$installPackageProviders = {
    # Install the NuGet package provider
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
}
# Install modules
$installModules = {
    # Install the NTFSSecurity PowerShell modules
    Install-Module "NTFSSecurity","OZO","OZOAD","OZOFiles","OZOLogger","OZOStrings" -Force
}
# Install scripts
$installScripts = {
    # Install OZO PowerShell scripts
    Install-Script "ozo-windows-event-log-provider-setup" -Force
}
# Run OZO Windows Event Log Provider setup script
$ozoWELPsetup = {
    # Execute the OZO Windows Event Log Provider setup
    & ozo-windows-event-log-provider-setup
}
# Enable remote desktop
$enableRemoteDesktop = {
    # Enable remote desktop
    Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "UserAuthentication" -Value 1
}
# Remove installation IP
$removeInstallationIP = {
    # Remove the installation IP
    Remove-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress $installationIP
}
# Join domain
$joinDomain = {
    Add-Computer -DomainName "CONTOSO"
}
# Install Modules
$installModules = {
    Install-Module NTFSSecurity -Force
}
# Create share folder
$createShareFolder = {
    New-Item -ItemType Directory -Path $sharePath
}
# Set NTFS permissions
$setNTFSPermissions = {
    # Import modules
    Import-Module NTFSSecurity
    # Set local filesystem ACLs
    $acl = (Get-Acl -Path $sharePath)
    $acl.SetAccessRuleProtection($true,$true)
    Set-Acl -Path $sharePath -AclObject $acl
    Remove-NTFSAccess -Path $sharePath -Account "BUILTIN\Users" -AccessRights CreateDirectories
    Remove-NTFSAccess -Path $sharePath -Account "BUILTIN\Users" -AccessRights CreateFiles
    Remove-NTFSAccess -Path $sharePath -Account "BUILTIN\Users" -AccessRights ReadAndExecute
    Add-NTFSAccess -Path $sharePath -Account "CONTOSO\Domain Users" -AccessRights "ReadAndExecute" -AccessType "Allow" -AppliesTo "ThisFolderOnly"
    Add-NTFSAccess -Path $sharePath -Account "CONTOSO\All Shares Full Control" -AccessRights "FullControl" -AccessType "Allow" -AppliesTo "ThisFolderSubfoldersAndFiles"
    # Iterate over Units
    ForEach ($unit in $units) {
        New-Item -ItemType Directory -Path "$sharePath\$unit"
        Add-NTFSAccess -Path "$sharePath\$unit" -Account "CONTOSO\$unit Share Modify" -AccessRights "Modify" -AccessType "Allow" -AppliesTo "ThisFolderSubfoldersAndFiles"
        Add-NTFSAccess -Path "$sharePath\$unit" -Account "CONTOSO\$unit Share Read" -AccessRights "ReadAndExecute" -AccessType "Allow" -AppliesTo "ThisFolderSubfoldersAndFiles"
    }
}
# Create SMB share
$createSMBShare = {
    # Share permissions
    New-SmbShare -FolderEnumerationMode "AccessBased" -FullAccess "NT AUTHORITY\Authenticated Users" -Name "Share" -Path "C:\Share"
}

# MAIN
# Start transcript
Start-Transcript -Path "C:\ProgramData\AD Lab\ad-lab-configure-server-transcript.txt"
# Add a DNS record for this server in AD DNS
Invoke-Command -ComputerName $dcIP -ScriptBlock $configureDNS
# Add a new IP address and restart
Invoke-Command -ComputerName $installationIP -ScriptBlock $addNewIPAddress
Invoke-Command -ComputerName $installationIP -ScriptBlock $installFeatures
Invoke-Command -ComputerName $installationIP -ScriptBlock $installPackageProviders
Invoke-Command -ComputerName $installationIP -ScriptBlock $installModules
Invoke-Command -ComputerName $installationIP -ScriptBlock $installScripts
Invoke-Command -ComputerName $installationIP -ScriptBlock $ozoWELPsetup
Invoke-Command -ComputerName $installationIP -ScriptBlock $enableRemoteDesktop
Restart-Computer -ComputerName $ipAddress -Wait -For PowerShell
# Remove the installation IP, join the server to the domain, and restart
Invoke-Command -ComputerName $ipAddress -ScriptBlock $removeInstallationIP
Invoke-Command -ComputerName $ipAddress - ScriptBlock $joinDomain
Restart-Computer -ComputerName $ipAddress -Wait -For PowerShell
# Install modules, create share folder
Invoke-Command -ComputerName $ipAddress -ScriptBlock $installModules
Invoke-Command -ComputerName $ipAddress -ScriptBlock $createShareFolder
Invoke-Command -ComputerName $ipAddress -ScriptBlock $setNTFSPermissions
Invoke-Command -ComputerName $ipAddress -ScriptBlock $createSMBShare
Restart-Computer -ComputerName $ipAddress -Wait -For PowerShell
# Stop transcript
Stop-Transcript
