# Set the local Ethernet adapter to dhcp and set the primary DNS
Remove-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress "172.16.1.99"
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses $dcIP
# Add this client to the domain
Add-Computer -DomainName "CONTOSO" -OUPath "OU=IT,OU=Workstations,DC=contoso,DC=com" -Restart
