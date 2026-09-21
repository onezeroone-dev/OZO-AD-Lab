#Requires -Modules OZOLogger -RunAsAdministrator

<#PSScriptInfo
    .VERSION 0.1.2
    .GUID 37a6282a-79b7-48ee-a182-a01e343b2139
    .AUTHOR Andy Lievertz <alievertz@onezeroone.dev>
    .COMPANYNAME One Zero One
    .COPYRIGHT This script is released under the terms of the GNU General Public License ("GPL") version 2.0.
    .TAGS
    .LICENSEURI https://github.com/onezeroone-dev/OZO-AD-Lab-Configure-Lab/blob/main/LICENSE
    .PROJECTURI https://github.com/onezeroone-dev/OZO-AD-Lab-Configure-Lab
    .ICONURI
    .EXTERNALMODULEDEPENDENCIES
    .REQUIREDSCRIPTS
    .EXTERNALSCRIPTDEPENDENCIES
    .RELEASENOTES https://github.com/onezeroone-dev/OZO-AD-Lab-Configure-Lab/blob/main/CHANGELOG.md
#>

<#
    .SYNOPSIS
    See description.
    .DESCRIPTION
    Configures an OZO AD Lab.
    .PARAMETER Configuration
    The path to the JSON configuration file.
    .EXAMPLE
    ozo-ad-lab-configure-lab
    .LINK
    https://github.com/onezeroone-dev/OZO-AD-Lab-Configure-Lab/blob/main/README.md
#>

# PARAMETERS
[CmdletBinding()] Param (
    [Parameter(Mandatory=$false)][String] $Configuration = (Join-Path -Path $Env:SystemDrive -ChildPath "OZO-AD-Lab\ozo-ad-lab-configure-lab.json")
)

# SCRIPTBLOCKS
# Set NTFS permissions
$setNTFSPermissions = {
    # Import modules
    Import-Module NTFSSecurity
    # Set local filesystem ACLs
    $acl = (Get-Acl -Path "C:\Share")
    $acl.SetAccessRuleProtection($true,$true)
    Set-Acl -Path "C:\Share" -AclObject $acl
    Remove-NTFSAccess -Path "C:\Share" -Account "BUILTIN\Users" -AccessRights CreateDirectories
    Remove-NTFSAccess -Path "C:\Share" -Account "BUILTIN\Users" -AccessRights CreateFiles
    Remove-NTFSAccess -Path "C:\Share" -Account "BUILTIN\Users" -AccessRights ReadAndExecute
    Add-NTFSAccess -Path "C:\Share" -Account ("CONTOSO\Domain Users") -AccessRights "ReadAndExecute" -AccessType "Allow" -AppliesTo "ThisFolderOnly"
    Add-NTFSAccess -Path "C:\Share" -Account ("CONTOSO\Domain Administrators") -AccessRights "FullControl" -AccessType "Allow" -AppliesTo "ThisFolderSubfoldersAndFiles"
}

# VARIABLES
[PSCredential] $OZOADCredential = $null

# MAIN
# Try to get the Administrator credential from the user
Try {
    $OZOADCredential = (Get-Credential -Message "Enter the Administrator credential for the OZO AD Lab" -UserName "Administrator")
} Catch {
    Write-Error "Failed to get the Administrator credential: $_"
    Exit 1
}
# Start the transcript
Start-Transcript -Path (Join-Path -Path $Env:ProgramData -ChildPath "OZO AD Lab\ozo-ad-lab-configure.txt")
# Determine that the DC is reachable for remote PowerShell
If ((Test-NetConnection -ComputerName "dc.contoso.com" -Port 5985).TcpTestSucceeded -eq $true) {
    # DC is reachable; set NTFS permissions
    Invoke-Command -ComputerName "dc.contoso.com" -ScriptBlock $setNTFSPermissions
} Else {
    # DC is not reachable
    Write-OZOProvider -Level "Warning" -Message "DC is not reachable on its production IP for remote PowerShell."
}
<#
[String] $Configuration = (Join-Path -Path $Env:SystemDrive -ChildPath "OZO-AD-Lab\DC\ozo-ad-lab-configuration.json")
[String] $OutDir = (Join-Path -Path $Env:SystemDrive -ChildPath "ProgramData\OZO-AD-Lab")
# Create directory objects
& ozo-ad-manage-directory-objects -Configuration $Configuration -OutDir $OutDir
# Create delegations
& ozo-ad-manage-delegations -Configuration $Configuration -OutDir $OutDir
# Move default group objects
Get-ADObject -Filter * -SearchBase "CN=Users,DC=contoso,DC=com" | Where-Object { $_.ObjectClass -eq "group" } | Move-ADObject -TargetPath "OU=Domain Groups,DC=contoso,DC=com"
# Move default user objects
Get-ADObject -Filter * -SearchBase "CN=Users,DC=contoso,DC=com" | Where-Object { $_.ObjectClass -eq "user" } | Move-ADObject -TargetPath "OU=Domain Users,DC=contoso,DC=com"
#>
# Stop transcript
Stop-Transcript
