<#
.SYNOPSIS
Finds and optionally removes role assignments with unknown or deleted principals across all Azure subscriptions.

.DESCRIPTION
This script scans all accessible Azure subscriptions for role assignments assigned to deleted or unknown users/groups.
It provides two modes of operation:
- Report Only (default): Lists all unknown principals without making changes
- Fix: Prompts the user to delete each unknown principal found

The script can export results to a CSV file and includes comprehensive logging and error handling.

.PARAMETER None
The script uses interactive prompts to determine the operating mode.

.EXAMPLE
.\Remove-Unknown-roles-AIM.ps1
Runs the script and prompts for the operating mode.

.NOTES
- Requires Azure PowerShell module and authenticated connection (Connect-AzAccount)
- Requires permissions to read role assignments across all subscriptions
- Delete operations require additional permissions on the target scopes
- Results are returned as PSCustomObject array and optionally exported to CSV

.AUTHOR
Olav Tvedt
#>

# Find all role assignments with unknown (deleted) users/groups across all subscriptions
# Prompts for mode at startup: ReportOnly (default) or Fix

$modeChoice = $Host.UI.PromptForChoice(
    "Run Mode",
    "Select how the script should handle unknown role assignments:",
    @(
        [System.Management.Automation.Host.ChoiceDescription]::new("&Report only", "Scan and list all unknown principals without making any changes."),
        [System.Management.Automation.Host.ChoiceDescription]::new("&Fix (delete)", "Prompt to delete each unknown principal found.")
    ),
    0  # default: Report only
)

$reportOnly = ($modeChoice -eq 0)

if ($reportOnly) {
    Write-Host "`nMode: Report only — no changes will be made." -ForegroundColor Cyan
} else {
    Write-Host "`nMode: Fix — you will be prompted to delete each unknown principal." -ForegroundColor Yellow
}

$allUnknownPrincipals = [System.Collections.Generic.List[PSCustomObject]]::new()

$subscriptions = Get-AzSubscription -WarningAction SilentlyContinue -ErrorAction SilentlyContinue

if (-not $subscriptions) {
    Write-Error "No subscriptions found. Make sure you are logged in with Connect-AzAccount."
    return
}

Write-Host "Found $($subscriptions.Count) subscription(s) to scan." -ForegroundColor Cyan

foreach ($subscription in $subscriptions) {
    Write-Host "Scanning subscription: $($subscription.Name) [$($subscription.Id)]" -ForegroundColor Cyan

    try {
        $null = Set-AzContext -SubscriptionId $subscription.Id -ErrorAction Stop
    }
    catch {
        Write-Warning "Could not set context to subscription $($subscription.Name): $_"
        continue
    }

    try {
        # Get all role assignments for the entire subscription in one call
        $roleAssignments = Get-AzRoleAssignment -IncludeClassicAdministrators:$false -ErrorAction SilentlyContinue

        foreach ($assignment in $roleAssignments) {
            # Unknown/deleted principals have no display name or are explicitly marked Unknown
            if ([string]::IsNullOrWhiteSpace($assignment.DisplayName) -or
                $assignment.DisplayName -like "Unknown" -or
                $assignment.ObjectType -eq "Unknown") {

                $displayName = if ([string]::IsNullOrWhiteSpace($assignment.DisplayName)) { "Unknown/Deleted" } else { $assignment.DisplayName }

                $entry = [PSCustomObject]@{
                    SubscriptionName   = $subscription.Name
                    SubscriptionId     = $subscription.Id
                    RoleDefinitionName = $assignment.RoleDefinitionName
                    Scope              = $assignment.Scope
                    DisplayName        = $displayName
                    ObjectId           = $assignment.ObjectId
                    ObjectType         = $assignment.ObjectType
                    Deleted            = $false
                }

                Write-Host "`n--- Unknown principal found ---" -ForegroundColor Yellow
                Write-Host "  Subscription : $($subscription.Name)"
                Write-Host "  Role         : $($assignment.RoleDefinitionName)"
                Write-Host "  Scope        : $($assignment.Scope)"
                Write-Host "  ObjectId     : $($assignment.ObjectId)"
                Write-Host "  ObjectType   : $($assignment.ObjectType)"

                if ($reportOnly) {
                    Write-Host "  -> Report only — skipped." -ForegroundColor Gray
                }
                else {
                    $confirm = Read-Host "  Delete this role assignment? [y/N]"
                    if ($confirm -eq 'y' -or $confirm -eq 'Y') {
                        try {
                            Remove-AzRoleAssignment -ObjectId $assignment.ObjectId `
                                -RoleDefinitionName $assignment.RoleDefinitionName `
                                -Scope $assignment.Scope `
                                -ErrorAction Stop
                            Write-Host "  -> Deleted." -ForegroundColor Green
                            $entry.Deleted = $true
                        }
                        catch {
                            Write-Warning "  -> Failed to delete: $_"
                        }
                    }
                    else {
                        Write-Host "  -> Skipped." -ForegroundColor Gray
                    }
                }

                $allUnknownPrincipals.Add($entry)
            }
        }
    }
    catch {
        Write-Warning "Error scanning subscription $($subscription.Name): $_"
    }
}

# Display summary
if ($allUnknownPrincipals.Count -gt 0) {
    $deleted = $allUnknownPrincipals | Where-Object { $_.Deleted }
    $skipped = $allUnknownPrincipals | Where-Object { -not $_.Deleted }

    if ($reportOnly) {
        Write-Host "`nSummary (Report only): $($allUnknownPrincipals.Count) unknown principal(s) found — no changes made." -ForegroundColor Cyan
    } else {
        Write-Host "`nSummary: $($allUnknownPrincipals.Count) unknown principal(s) found — $($deleted.Count) deleted, $($skipped.Count) skipped." -ForegroundColor Green
    }
    $allUnknownPrincipals | Format-Table -AutoSize -Property SubscriptionName, RoleDefinitionName, DisplayName, ObjectId, Scope, Deleted

    # Ask if user wants to export
    $exportChoice = $Host.UI.PromptForChoice(
        "Export Results",
        "Do you want to export the results to a CSV file?",
        @(
            [System.Management.Automation.Host.ChoiceDescription]::new("&Yes", "Export to CSV file."),
            [System.Management.Automation.Host.ChoiceDescription]::new("&No", "Skip export.")
        ),
        0  # default: Yes
    )

    if ($exportChoice -eq 0) {
        $defaultPath = "$PSScriptRoot\UnknownPrincipals_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
        $exportPath = Read-Host "Enter export path (default: $defaultPath)"
        if ([string]::IsNullOrWhiteSpace($exportPath)) {
            $exportPath = $defaultPath
        }

        try {
            $allUnknownPrincipals | Export-Csv -Path $exportPath -NoTypeInformation
            Write-Host "Detailed report exported to: $exportPath" -ForegroundColor Cyan
        }
        catch {
            Write-Warning "Failed to export to $exportPath : $_"
        }
    }
}
else {
    Write-Host "`nNo role assignments with unknown/deleted principals found." -ForegroundColor Yellow
}

return $allUnknownPrincipals
