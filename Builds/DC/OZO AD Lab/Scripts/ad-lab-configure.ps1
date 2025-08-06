## VARIABLES
[String]         $DC     = "DC=contoso,DC=com"
[Array]          $units  = @("Administration","IT","Development","Finance","Human Resources","Marketing","Operations")
[Json]           $Configuration = (Get-Content -Path "C:\ProgramData\OZO AD Lab\ad-lab-configure.json" | ConvertFrom-Json)
## START TRANSCRIPT
Start-Transcript -Append -Path "C:\ProgramData\AD Lab\transcript.txt"

Install-Module DSACL -Force
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
# Configure DFS
New-DfsnRoot 
#### ORGANIZATIONAL UNITS
# Create additional top-level OUs
ForEach ($OU in $Configuration.ADOrganizationalUnits) {
    New-ADOrganizationalUnit -Name $OU.Name -Path $OU.Path
}
# Create additional second-level OUs
ForEach ($unit in $units) {
    ForEach ($ou in $OUs) {
        New-ADOrganizationalUnit -Name $unit -Path "OU=$ou,$DC"
    }
}
# Move default objects
ForEach ($adObject in (Get-ADObject -Filter * -SearchBase "CN=Users,$DC")) {
    Switch($adObject.ObjectClass) {
        "user" {
            Move-ADObject -Identity $adObject.DistinguishedName -TargetPath "OU=Domain Users,$DC"
        }
        "group" {
            Move-ADObject -Identity $adObject.DistinguishedName -TargetPath "OU=Domain Groups,$DC"
        }
    }
}
## GROUPS
ForEach ($group in $groups) {
    New-AdGroup -Name $group.Name -GroupScope $group.Scope -Path $group.Path
    If ([String]::IsNullOrEmpty($group.Members)) {
        Add-ADGroupMember -Identity $group.Name -Members ($group.Members -Split ";")
    }
}
## PEOPLE
# Create users
ForEach ($user in $users) {
    # Construct the samAccountName
    $samAccountName = ($user.First[0] + $user.Last).ToLower()
    New-ADUser -AccountPassword (ConvertTo-SecureString -AsPlainText -String $user.Password -Force) -Company "Contoso, Ltd." -Description $user.Title -DisplayName ($user.First + " " + $user.Last) -Division $user.Division -EmailAddress ($samAccountName + "@contoso.com") -EmployeeNumber $user.EmployeeID -Enabled $true -GivenName $user.First -Initials ($user.First[0] + $user.Last[0]).ToUpper() -Name $samAccountName -Path ("OU=" + $user.Division + ",OU=People,$DC") -Surname $user.Last -Title $user.Title
    # Add to groups
    If ([String]::IsNullOrEmpty($user.Groups)) {
        ForEach ($group in ($user.Groups -Split ";")) {
            Add-ADGroupMember -Identity $group -Members $samAccountName
        }
    }
}
## COMPUTERS
# Create computers
New-ADComputer -DisplayName "client" -Enabled $true -Name "client" -Path "OU=IT,OU=Workstations,$DC"
New-ADComputer -DisplayName "server" -Enabled $true -Name "server" -Path "OU=IT,OU=Servers,$DC"

## GROUP POLICY
ForEach ($ou in "Servers","Workstations","People") {
    New-GPO -Name "All $ou Settings" | New-GPLink -Target "OU=$ou,$DC" -LinkEnabled Yes -Enforced Yes
}
# Create and link unit policies
ForEach ($unit in $units) {
    ForEach ($ou in "Servers","Workstations","People") {
        New-GPO -Name "$unit $ou Settings" | New-GPLink -Target "OU=$unit,OU=$ou,$DC"
    }
}

# Call OZO AD Manage Delegations
#&

## STOP TRANSCRIPT
Stop-Transcript
