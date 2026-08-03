# VARIABLES
[SecureString] $encryptedLabPassword = (ConvertTo-SecureString -AsPlainText -String 'OZOADL@b$ecurePassw0rd' -Force)
[String] $dcIP = "172.16.1.2"
[String] $gwIP = "172.16.1.1"
[String] $installationIP = "172.16.1.100"

# SCRIPTBLOCKS
# Add new IP address
$addNewIPAddress = {
    # Update the Ethernet IP address
    New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress $dcIP -PrefixLength 24 -DefaultGateway $gwIP
}
# Install new features scriptblock
$installFeatures = {
    # Install the DHCP server
    Install-WindowsFeature DHCP -IncludeManagementTools
    # Install DFS
    Install-WindowsFeature FS-DFS-Replication -IncludeManagementTools
    # Install AD Domain Services
    Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
    # Install Remote Server Administration Tools
    Install-WindowsFeature -Name "RSAT-ADDS","RSAT-ADLDS"    
}
# Install package providers
$installPackageProviders = {
    # Install the NuGet package provider
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
}
# Install modules
$installModules = {
    # Install the DSACL and OZO PowerShell modules
    Install-Module "DSACL","OZO","OZOAD","OZOFiles","OZOLogger","OZOStrings" -Force
}
# Install scripts
$installScripts = {
    # Install OZO PowerShell scripts
    Install-Script "ozo-ad-manage-directory-objects","ozo-ad-manage-delegations","ozo-windows-event-log-provider-setup" -Force
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
# Install forest
$installForest = {
    # Import modules
    Import-Module ActiveDirectory,ADDSDeployment,DSACL,GroupPolicy
    # Set local Administrator password
    #Set-LocalUser -Name "Administrator" -Password $encryptedLabPassword
    # Install contoso.com forest
    Install-ADDSForest -DomainName "contoso.com" -SafeModeAdministratorPassword $encryptedLabPassword -DomainMode 7 -DomainNetbiosName "CONTOSO" -ForestMode 7 -InstallDns -NoRebootOnCompletion -Force

}
# Configure DNS
$configureDNS = {
    # Configure DNS
    Add-DnsServerPrimaryZone -NetworkID "172.16.1.0/24" -ReplicationScope "Forest"
    Add-DnsServerResourceRecordA -CreatePtr -Name "router" -IPv4Address $gwIP -ZoneName "contoso.com"
}
# Configure DHCP
$configureDHCP = {
    # Add DHCP security groups
    & netsh dhcp add securitygroups
    # Configure DHCP
    Add-DhcpServerInDC -DnsName "dc.contoso.com" -IPAddress $dcIP
    Set-ItemProperty -Path "registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\ServerManager\Roles\12" -Name ConfigurationState -Value 2
    Set-DhcpServerv4DnsSetting -ComputerName "dc.contoso.com" -DynamicUpdates "Always" -DeleteDnsRRonLeaseExpiry $True
    Add-DhcpServerv4Scope -name "Clients" -StartRange 172.16.1.1 -EndRange 172.16.1.254 -SubnetMask 255.255.255.0 -State Active
    Add-DhcpServerv4ExclusionRange -ScopeID 172.16.1.0 -StartRange 172.16.1.1 -EndRange 172.16.1.100
    Set-DhcpServerv4OptionValue -OptionID 3 -Value $gwIP -ScopeID 172.16.1.0 -ComputerName "dc.contoso.com"
    Set-DhcpServerv4OptionValue -DnsDomain "contoso.com" -DnsServer $dcIP
    Restart-Service dhcpserver 
}
# Populate AD
$populateAD = {
    param($ozoADLabConfigurationJson)
    # Call ozo-ad-manage-directory-objects
    & ozo-ad-manage-directory-objects -Configuration (Join-Path -Path $Env:SystemDrive -ChildPath "OZO-AD-Lab\DC\ozo-ad-lab-configuration.json") -OutDir (Join-Path -Path $Env:SystemDrive -ChildPath "ProgramData\OZO-AD-Lab")
    # Call ozo-ad-manage-delegations
    & ozo-ad-manage-directory-objects -Configuration (Join-Path -Path $Env:SystemDrive -ChildPath "OZO-AD-Lab\DC\ozo-ad-lab-configuration.json") -OutDir (Join-Path -Path $Env:SystemDrive -ChildPath "ProgramData\OZO-AD-Lab")
    # Move default objects
    ForEach ($adObject in (Get-ADObject -Filter * -SearchBase "CN=Users,$DC")) {
        # Swtich on ObjectClass
        Switch($adObject.ObjectClass) {
            "user" {
                Move-ADObject -Identity $adObject.DistinguishedName -TargetPath "OU=Domain Users,DC=contoso,DC=com"
                break
            }
            "group" {
                Move-ADObject -Identity $adObject.DistinguishedName -TargetPath "OU=Domain Groups,DC=contoso,DC=com"
                break
            }
        }
    }
}

# MAIN
# Start the transcript
Start-Transcript -Path "C:\ProgramData\OZO AD Lab\ad-lab-configure-dc-transcript.txt"
# Run the installFeatures, installModules, installScripts, and addNewIPAddress script blocks on the server, and restart
Invoke-Command -ComputerName $installationIP -ScriptBlock $addNewIPAddress
Invoke-Command -ComputerName $installationIP -ScriptBlock $installFeatures
Invoke-Command -ComputerName $installationIP -ScriptBlock $installPackageProviders
Invoke-Command -ComputerName $installationIP -ScriptBlock $installModules
Invoke-Command -ComputerName $installationIP -ScriptBlock $installScripts
Invoke-Command -ComputerName $installationIP -ScriptBlock $ozoWELPsetup
Invoke-Command -ComputerName $installationIP -ScriptBlock $enableRemoteDesktop
Restart-Computer -ComputerName $installationIP -Wait -For PowerShell
# Run the post-reboot script block on the domain controller and restart
Invoke-Command -ComputerName $dcIP -ScriptBlock $removeInstallationIP
Invoke-Command -ComputerName $dcIP -ScriptBlock $installForest
Restart-Computer -ComputerName $dcIP -Wait -For PowerShell
# Configure DNS, configure DHCP, populate AD, and remove the installation IP and restart
Invoke-Command -ComputerName $dcIP -ScriptBlock $configureDNS
Invoke-Command -ComputerName $dcIP -ScriptBlock $configureDHCP
Invoke-Command -ComputerName $dcIP -ScriptBlock $populateAD
# Stop the transcript
Stop-Transcript
