<#
.SYNOPSIS
    Retrieves all Azure role assignments (active and eligible) for a specified Azure AD group across all subscriptions, and exports the results to a CSV file.

.DESCRIPTION
    This script connects to Azure using a specified tenant ID, filters out unwanted subscriptions, and retrieves both active and eligible role assignments for the Azure AD group 'az_pim_mgmt_root_owner' in each subscription.
    The results are displayed in a table and exported to a timestamped CSV file in a specified directory.

.PARAMETER TenantId
    The Azure Active Directory tenant ID to connect to.

.PARAMETER Group01
    The Azure AD group to search for role assignments (hardcoded as 'az_pim_mgmt_root_owner').

.PARAMETER Subs
    The list of Azure subscriptions, excluding those with names matching 'Visual Studio', 'Gratis', or 'Tilgang til Azure Active Directory'.

.OUTPUTS
    Displays a formatted table of role assignments and exports the results to a CSV file.

.NOTES
    - Requires the Az PowerShell module.
    - The export directory can be changed as needed.
    - The script creates the export directory if it does not exist.

.EXAMPLE
    # Run the script to retrieve and export Azure role assignments for the specified group.
    .\Get-AllAzureRolesGroup.ps1

#>
Connect-AzAccount 
$Subs = Get-AzSubscription | Where-Object { $_.Name -notmatch 'Visual Studio|Free' }
$Group01 = Get-AzADGroup -SearchString 'security_group_name'
$results = @()

ForEach ($sub in $Subs) {
    Set-AzContext -SubscriptionId $sub.Id
    
    # Active Assignments
    $activeAssignments = Get-AzRoleAssignment -ObjectId $Group01.Id -Scope "/subscriptions/$($sub.Id)"
    foreach ($assignment in $activeAssignments) {
        $results += [pscustomobject]@{
            SubscriptionName   = $sub.Name
            GroupName          = $assignment.DisplayName
            RoleDefinitionName = $assignment.RoleDefinitionName
            Scope              = $assignment.Scope
            AssignmentType     = 'Active'
        }
    }
    
    # Eligible Assignments
    $eligibleAssignments = Get-AzRoleEligibilitySchedule -Scope "/subscriptions/$($sub.Id)" -Filter "principalId eq '$($Group01.Id)'"
    foreach ($assignment in $eligibleAssignments) {
        $roleDefinitionId = ($assignment.RoleDefinitionId -split '/')[-1]
        $roleDefinition = Get-AzRoleDefinition -Id $roleDefinitionId
        $results += [pscustomobject]@{
            SubscriptionName   = $sub.Name
            GroupName          = $Group01.DisplayName
            RoleDefinitionName = $roleDefinition.Name
            Scope              = $assignment.Scope
            AssignmentType     = 'Eligible'
        }
    }
}

# Display results in a table
$results | Format-Table

# Export to CSV
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$exportDir = "C:\temp" # You can change this path as needed
$fileName = "$exportDir\$($Group01.DisplayName)-AzureRoles-$($timestamp).csv"
$results | Export-Csv -Path $fileName -NoTypeInformation

Write-Host "Results exported to $fileName"
