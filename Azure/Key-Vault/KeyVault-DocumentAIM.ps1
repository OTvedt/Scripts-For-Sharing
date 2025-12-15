<#
.SYNOPSIS
    Documents Azure Identity and Access Management (AIM) access to a specific Azure Key Vault.

.DESCRIPTION
    This script retrieves and exports all access information for the Key Vault 'adf-kv-prod-01' 
    in the 'data-plattform-prod-01' subscription. It generates three CSV reports:
    
    1. RBAC Role Assignments - All RBAC assignments with Key Vault roles
    2. Access Policies - Key Vault access policies showing permissions to keys, secrets, and certificates
    3. Group Members - Detailed membership information for any groups that have Key Vault RBAC assignments
    
    The script connects to Azure, retrieves the Key Vault configuration, and exports the access 
    information with a timestamp for audit and documentation purposes.

.PARAMETER None
    This script does not accept parameters. Key Vault and subscription names are hardcoded.

.EXAMPLE
    .\KeyVault-DocumentAIM.ps1
    
    Exports three CSV files to c:\temp\:
    - KeyVault-Access-RBAC-20240115-143022.csv
    - KeyVault-Access-Policies-20240115-143022.csv
    - KeyVault-Access-GroupMembers-20240115-143022.csv

.OUTPUTS
    CSV files containing:
    - RBAC assignments with Key Vault roles (DisplayName, SignInName, RoleDefinitionName, ObjectType, ObjectId, Scope)
    - Access policies (DisplayName, ObjectId, PermissionsToKeys, PermissionsToSecrets, PermissionsToCertificates)
    - Group members (GroupName, GroupObjectId, GroupRole, MemberDisplayName, MemberUserPrincipalName, MemberObjectId, MemberType)

.NOTES
    Author: Olav Tvedt
    Prerequisites:
    - Az.KeyVault module
    - Az.Resources module
    - Az.Accounts module
    - Appropriate permissions to read Key Vault configuration and Azure AD groups
    - Target subscription: "<Your-Subs-01>"
    - Target Key Vault: "<Your-Key-Vault>"
#>
# Document AIM access to Key Vault
# Key Vault: <Your-Key-Vault>"
# Subscription: "<Your-Subs-01>"

# Set the subscription context
Set-AzContext -SubscriptionName "<Your-Subs-01>"

# Get the Key Vault
$keyVaultName = <Your-Key-Vault>"
$keyVault = Get-AzKeyVault -VaultName $keyVaultName

if ($null -eq $keyVault) {
    Write-Error "Key Vault '$keyVaultName' not found"
    exit
}

# Get RBAC role assignments
$rbacAssignments = Get-AzRoleAssignment -Scope $keyVault.ResourceId | Select-Object `
    DisplayName,
    SignInName,
    RoleDefinitionName,
    ObjectType,
    ObjectId,
    Scope

# Get Access Policies
$accessPolicies = $keyVault.AccessPolicies | Select-Object `
    DisplayName,
    ObjectId,
    @{Name='PermissionsToKeys';Expression={$_.PermissionsToKeys -join ', '}},
    @{Name='PermissionsToSecrets';Expression={$_.PermissionsToSecrets -join ', '}},
    @{Name='PermissionsToCertificates';Expression={$_.PermissionsToCertificates -join ', '}}

# Export results
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$rbacPath = "c:\temp\KeyVault-Access-RBAC-$timestamp.csv"
$policiesPath = "KeyVault-Access-Policies-$timestamp.csv"

$rbacAssignments | Where-Object { $_.RoleDefinitionName -like "*Key Vault*" } | Export-Csv -Path $rbacPath -NoTypeInformation -Encoding unicode
$accessPolicies | Export-Csv -Path $policiesPath -NoTypeInformation -Encoding unicode

Write-Host "RBAC assignments exported to: $rbacPath"
Write-Host "Access policies exported to: $policiesPath"
Write-Host "Total RBAC assignments: $($rbacAssignments.Count)"
Write-Host "Total Access policies: $($accessPolicies.Count)"

# Get group members if there are any groups in RBAC assignments
$groupAssignments = $rbacAssignments | Where-Object { $_.ObjectType -eq 'Group' -and $_.RoleDefinitionName -like "*Key Vault*"}

if ($groupAssignments.Count -gt 0) {
    $groupMembers = @()
    
    foreach ($group in $groupAssignments) {
        $members = Get-AzADGroupMember -GroupObjectId $group.ObjectId
        
        foreach ($member in $members) {
            $groupMembers += [PSCustomObject]@{
                GroupName = $group.DisplayName
                GroupObjectId = $group.ObjectId
                GroupRole = $group.RoleDefinitionName
                AssignmentType = 'Active'
                MemberDisplayName = $member.DisplayName
                MemberUserPrincipalName = $member.UserPrincipalName
                MemberObjectId = $member.Id
                MemberType = $member.AdditionalProperties['@odata.type'] -replace '#microsoft.graph.', ''
            }
        }
    }
    
    # Get eligible role assignments (PIM)
    $eligibleAssignments = Get-AzRoleEligibilityScheduleInstance -Scope $keyVault.ResourceId # | Where-Object { $_.RoleDefinitionName -like "*Key Vault*" -and $_.PrincipalType -eq 'Group' }
    
    foreach ($eligible in $eligibleAssignments) {
        $members = Get-AzADGroupMember -GroupObjectId $eligible.PrincipalId
        
        foreach ($member in $members) {
            $groupMembers += [PSCustomObject]@{
                GroupName = $eligible.PrincipalDisplayName
                GroupObjectId = $eligible.PrincipalId
                GroupRole = $eligible.RoleDefinitionDisplayName
                AssignmentType = 'Eligible'
                MemberDisplayName = $member.DisplayName
                MemberUserPrincipalName = $member.UserPrincipalName
                MemberObjectId = $member.Id
                MemberType = $member.AdditionalProperties['@odata.type'] -replace '#microsoft.graph.', ''
            }
        }
    }
    
    $groupMembersPath = "c:\temp\KeyVault-Access-GroupMembers-$timestamp.csv"
    $groupMembers | Where-Object { $_.GroupRole -like "*Key Vault*"} | Export-Csv -Path $groupMembersPath -NoTypeInformation -Encoding unicode # add  -or $_.GroupRole -like"*<Your custom role name>*" or any other role you want documentet
    Write-Host "Group members exported to: $groupMembersPath"
    Write-Host "Total group members: $($groupMembers.Count)"
}
