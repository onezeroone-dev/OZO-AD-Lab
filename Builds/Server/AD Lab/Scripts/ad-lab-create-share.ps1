# Declare variables
[Array]  $units = @("Administration","IT","Development","Finance","Human Resources","Marketing","Operations")
[String] $sharePath = "C:\Share"

## START TRANSCRIPT
Start-Transcript -Path "C:\ProgramData\AD Lab\transcript.txt"

## MODULES
Install-Module NTFSSecurity -Force
Import-Module NTFSSecurity

## PERMISSIONS
# NTFS permissions; set local filesystem ACLs
# Set local filesystem ACLs
$acl = (Get-Acl -Path $sharePath)
$acl.SetAccessRuleProtection($true,$true)
Set-Acl -Path $sharePath -AclObject $acl
Remove-NTFSAccess -Path $sharePath -Account "BUILTIN\Users" -AccessRights CreateDirectories
Remove-NTFSAccess -Path $sharePath -Account "BUILTIN\Users" -AccessRights CreateFiles
Remove-NTFSAccess -Path $sharePath -Account "BUILTIN\Users" -AccessRights ReadAndExecute
Add-NTFSAccess -Path $sharePath -Account "CONTOSO\Domain Users" -AccessRights "ReadAndExecute" -AccessType "Allow" -AppliesTo "ThisFolderOnly"
Add-NTFSAccess -Path $sharePath -Account "CONTOSO\All Shares Full Control" -AccessRights "FullControl" -AccessType "Allow" -AppliesTo "ThisFolderSubfoldersAndFiles"
ForEach ($unit in $units) {
    Add-NTFSAccess -Path "$sharePath\$unit" -Account "CONTOSO\$unit Share Modify" -AccessRights "Modify" -AccessType "Allow" -AppliesTo "ThisFolderSubfoldersAndFiles"
    Add-NTFSAccess -Path "$sharePath\$unit" -Account "CONTOSO\$unit Share Read" -AccessRights "ReadAndExecute" -AccessType "Allow" -AppliesTo "ThisFolderSubfoldersAndFiles"
}
# Share permissions
New-SmbShare -FolderEnumerationMode "AccessBased" -FullAccess "NT AUTHORITY\Authenticated Users" -Name "Share" -Path "C:\Share"

## STOP TRANSCRIPT
Stop-Transcript
