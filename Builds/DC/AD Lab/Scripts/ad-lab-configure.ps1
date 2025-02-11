## VARIABLES
[String]         $DC    = "DC=contoso,DC=com"
[Array]          $OUs   = @("Groups","Servers","Workstations","Service Accounts","People")
[Array]          $units = @("Administration","IT","Development","Finance","Human Resources","Marketing","Operations")
[PSCustomObject] $users = (Import-Csv -Path "C:\ProgramData\AD Lab\ad-lab-users.csv")
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
#### ORGANIZATIONAL UNITS
# Create additional top-level OUs
New-ADOrganizationalUnit -Name "Domain Groups" -Path $DC
New-ADOrganizationalUnit -Name "Domain Users" -Path $DC
ForEach ($ou in $OUs) {
    New-ADOrganizationalUnit -Name $ou -Path $DC
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
# Create the "all" delegation and share groups, and the local administrators groups
ForEach ($ou in $OUs) {
    New-ADGroup -Name "All $ou Delegates" -Path "OU=Domain Groups,$DC" -GroupScope 1
}
New-ADGroup -Name "All GPO Delegates" -Path "OU=Domain Groups,$DC" -GroupScope 1
New-ADGroup -Name "All Shares Full Control" -Path "OU=Domain Groups,$DC" -GroupScope 1
New-ADGroup -Name "All Servers Local Administrators" -Path "OU=Domain Groups,$DC" -GroupScope 1
New-ADGroup -Name "All Workstations Local Administrators" -Path "OU=Domain Groups,$DC" -GroupScope 1
# Create organizational unit delegation groups
ForEach ($unit in $units) {
    ForEach ($ou in $OUs) {
        New-ADGroup -Name "$unit $ou Delegates" -Path "OU=Domain Groups,$DC" -GroupScope 1
    }
    New-ADGroup -Name "$unit GPO Delegates" -Path "OU=Domain Groups,$DC" -GroupScope 1
}
# Create unit delegation and file share groups
ForEach ($unit in $units) {
    New-ADGroup -Name "$unit AD Delegates" -Path "OU=$unit,OU=Groups,$DC" -GroupScope 1
    New-ADgroup -Name "$unit Share Read" -Path "OU=$unit,OU=Groups,$DC" -GroupScope 1
    New-ADGroup -Name "$unit Share Modify" -Path "OU=$unit,OU=Groups,$DC" -GroupScope 1
    New-ADGroup -Name "$unit Servers Local Administrators" -Path "OU=$unit,OU=Groups,$DC" -GroupScope 1
    New-ADGroup -Name "$unit Workstations Local Administrators" -Path "OU=$unit,OU=Groups,$DC" -GroupScope 1
}
# Add unit delegation groups to organizational delegation groups
ForEach ($unit in $units) {
    ForEach ($ou in $OUs) {
        Add-ADGroupMember -Identity "CN=$unit $ou Delegates,OU=Domain Groups,$DC" -Members (Get-ADGroup -Identity "$unit AD Delegates")
    }
    Add-ADGroupMember -Identity "CN=$unit GPO Delegates,OU=Domain Groups,$DC" -Members (Get-ADGroup -Identity "$unit AD Delegates")
}
# Add IT delegates to the All* delegation groups
ForEach ($ou in $OUs) {
    Add-ADGroupMember -Identity "CN=All $ou Delegates,OU=Domain Groups,$DC" -Members (Get-ADGroup -Identity "IT AD Delegates")
}
Add-ADGroupMember -Identity "CN=All GPO Delegates,OU=Domain Groups,$DC" -Members (Get-ADGroup -Identity "IT AD Delegates")

## DELEGATIONS
# Create "All" delegations
Add-DSACLFullControl -AccessType "Allow" -TargetDN "OU=Groups,$DC" -DelegateDN "CN=All Groups Delegates,OU=Domain Groups,$DC" -ObjectTypeName "Group"
Add-DSACLFullControl -AccessType "Allow" -TargetDN "OU=Servers,$DC" -DelegateDN "CN=All Servers Delegates,OU=Domain Groups,$DC" -ObjectTypeName "Computer"
Add-DSACLFullControl -AccessType "Allow" -TargetDN "OU=Workstations,$DC" -DelegateDN "CN=All Workstations Delegates,OU=Domain Groups,$DC" -ObjectTypeName "Computer"
Add-DSACLFullControl -AccessType "Allow" -TargetDN "OU=People,$DC" -DelegateDN "CN=All People Delegates,OU=Domain Groups,$DC" -ObjectTypeName "User"
# Create unit delegations
ForEach ($unit in $units) {
    Add-DSACLFullControl -AccessType "Allow" -TargetDN "OU=$unit,OU=Groups,$DC" -DelegateDN "CN=$unit Groups Delegates,OU=Domain Groups,$DC" -ObjectTypeName "Group"
    Add-DSACLFullControl -AccessType "Allow" -TargetDN "OU=$unit,OU=Servers,$DC" -DelegateDN "CN=$unit Servers Delegates,OU=Domain Groups,$DC" -ObjectTypeName "Computer"
    Add-DSACLFullControl -AccessType "Allow" -TargetDN "OU=$unit,OU=Workstations,$DC" -DelegateDN "CN=$unit Workstations Delegates,OU=Domain Groups,$DC" -ObjectTypeName "Computer"
    Add-DSACLFullControl -AccessType "Allow" -TargetDN "OU=$unit,OU=People,$DC" -DelegateDN "CN=$unit People Delegates,OU=Domain Groups,$DC" -ObjectTypeName "Group"
}

## PEOPLE
# Create users
ForEach ($user in $users) {
    # Construct the samAccountName
    $samAccountName = ($user.First[0] + $user.Last).ToLower()
    New-ADUser -AccountPassword (ConvertTo-SecureString -AsPlainText -String $user.Password -Force) -Company "Contoso, Ltd." -DisplayName ($user.First + " " + $user.Last) -Division $user.Division -EmailAddress ($samAccountName + "@contoso.com") -EmployeeNumber $user.EmployeeID -Enabled $true -GivenName $user.First -Initials ($user.First[0] + $user.Last[0]).ToUpper() -Name $samAccountName -Path ("OU=" + $user.Division + ",OU=People,$DC") -Surname $user.Last -Title $user.Title
}
# Add users to groups
ForEach ($user in $users) {
    # Get the AD user
    $adUser = (Get-ADUser -Identity ($user.First[0] + $user.Last).ToLower())
    # Add user to their division Server Share Modify group
    Add-ADGroupMember -Identity ($user.Division + " Share Modify") -Members $adUser
    # Add unit IT to their respective unit AD delegation group; GPO delegation group; and servers and workstations administration groups
    If ($user.Title -Like "*IT Specialist") {
        Add-ADGroupMember -Identity ($user.Division + " AD Delegates") -Members $adUser
        Add-ADGroupMember -Identity ($user.Division + " GPO Delegates") -Members $adUser
        Add-ADGroupMember -Identity ($user.Division + " Servers Local Administrators") -Members $adUser
        Add-ADGroupMember -Identity ($user.Division + " Workstations Local Administrators") -Members $adUser
    }
}
# Add IT users to groups
# Add Mae and Philip to the All Servers Local Admininstrators; All Shares Full Control, All AD Delegates, and All GPO Delegates groups
Add-ADGroupMember -Identity "All Servers Local Administrators" -Members "mmartinez","phardy"
Add-ADGroupMember -Identity "All Shares Full Control" -Members "mmartinez","phardy"
ForEach ($ou in $OUs) {
    Add-ADGroupMember -Identity "All $ou Delegates" -Members "mmartinez","phardy"
}
Add-ADGroupMember -Identity "All GPO Delegates" -Members "mmartinez","phardy"
# Add mae and Daryl to the All Workstation Local Administrators group
Add-ADGroupMember -Identity "All Workstations Local Administrators" -Members "mmartinez","drichards"

## COMPUTERS
# Create computers
New-ADComputer -DisplayName "client" -Enabled $true -Name "client" -Path "OU=IT,OU=Workstations,$DC"
New-ADComputer -DisplayName "server" -Enabled $true -Name "server" -Path "OU=IT,OU=Servers,$DC"

## GROUP POLICY
ForEach ($ou in "Servers","Workstations","People") {
    New-GPO -Name "All $ou Settings" | New-GPLink -Target "OU=$ou,$DC" -LinkEnabled Yes -Enforced Yes
    Set-GPPermission -Name "All $ou Settings" -TargetName "All GPO Delegates" -TargetType Group -PermissionLevel "GpoEditDeleteModifySecurity"
}
# Create and link unit policies
ForEach ($unit in $units) {
    ForEach ($ou in "Servers","Workstations","People") {
        New-GPO -Name "$unit $ou Settings" | New-GPLink -Target "OU=$unit,OU=$ou,$DC"
        Set-GPPermission -Name "$unit $ou Settings" -TargetName "$unit GPO Delegates" -TargetType Group -PermissionLevel "GpoEdit"
        Set-GPPermission -Name "$unit $ou Settings" -TargetName "All GPO Delegates" -TargetType Group -PermissionLevel "GpoEditDeleteModifySecurity"
    }
}

## STOP TRANSCRIPT
Stop-Transcript
