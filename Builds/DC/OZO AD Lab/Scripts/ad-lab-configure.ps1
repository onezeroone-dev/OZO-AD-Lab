## START TRANSCRIPT
Start-Transcript -Append -Path "C:\ProgramData\OZO AD Lab\transcript.txt"
# Import modules
Import-Module ActiveDirectory,DSACL,GroupPolicy
# Configure DNS
Add-DnsServerPrimaryZone -NetworkID "172.16.1.0/24" -ReplicationScope "Forest"
Add-DnsServerResourceRecordA -CreatePtr -Name "router" -IPv4Address 172.16.1.1 -ZoneName "contoso.com"
Add-DnsServerResourceRecordA -CreatePtr -Name "server" -IPv4Address 172.16.1.3 -ZoneName "contoso.com"
# Configure DHCP
Add-DhcpServerInDC -DnsName "dc.contoso.com" -IPAddress 172.16.1.2
Set-ItemProperty -Path "registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\ServerManager\Roles\12" -Name ConfigurationState -Value 2
Set-DhcpServerv4DnsSetting -ComputerName "dc.contoso.com" -DynamicUpdates "Always" -DeleteDnsRRonLeaseExpiry $True
Add-DhcpServerv4Scope -name "Clients" -StartRange 172.16.1.1 -EndRange 172.16.1.254 -SubnetMask 255.255.255.0 -State Active
Add-DhcpServerv4ExclusionRange -ScopeID 172.16.1.0 -StartRange 172.16.1.1 -EndRange 172.16.1.100
Set-DhcpServerv4OptionValue -OptionID 3 -Value 172.16.1.1 -ScopeID 172.16.1.0 -ComputerName "dc.contoso.com"
Set-DhcpServerv4OptionValue -DnsDomain "contoso.com" -DnsServer 172.16.1.2
Restart-Service dhcpserver 
# Call ozo-ad-manage-directory-objects
& ozo-ad-manage-directory-objects -Configuration (Join-Path -Path $Env:SystemDrive -ChildPath "OZO-AD-Lab\DC\ozo-ad-lab-configuration.json") -OutDir (Join-Path -Path $Env:SystemDrive -ChildPath "ProgramData\OZO-AD-Lab")
# Call ozo-ad-manage-delegations
& ozo-ad-manage-directory-objects -Configuration (Join-Path -Path $Env:SystemDrive -ChildPath "OZO-AD-Lab\DC\ozo-ad-lab-configuration.json") -OutDir (Join-Path -Path $Env:SystemDrive -ChildPath "ProgramData\OZO-AD-Lab")
# Move default objects
ForEach ($adObject in (Get-ADObject -Filter * -SearchBase "CN=Users,$DC")) {
    Switch($adObject.ObjectClass) {
        "user" {
            Move-ADObject -Identity $adObject.DistinguishedName -TargetPath "OU=Domain Users,DC=contoso,DC=com"
        }
        "group" {
            Move-ADObject -Identity $adObject.DistinguishedName -TargetPath "OU=Domain Groups,DC=contoso,DC=com"
        }
    }
}
## STOP TRANSCRIPT
Stop-Transcript
