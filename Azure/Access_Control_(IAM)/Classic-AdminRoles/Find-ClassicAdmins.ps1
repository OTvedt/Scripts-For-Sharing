<#
.SYNOPSIS
    This script retrieves and displays a list of Azure classic subscription administrators for all eligible Azure subscriptions.
    Based on https://wmatthyssen.com/2024/03/21/list-azure-classic-subscription-administrators-via-the-azure-portal-or-via-an-azure-powershell-script/

.DESCRIPTION
    The script performs the following tasks:
    1. Suppresses Azure PowerShell breaking change warnings.
    2. Retrieves all Azure subscriptions, excluding specific subscription types (e.g., "Microsoft Azure Enterprise", "Visual Studio", "Gratis", and "Tilgang til Azure Active Directory").
    3. Iterates through each subscription to find classic administrators (Service Administrators and Co-Administrators).
    4. Displays the list of classic administrators, if any are found.

.PARAMETERS
    None.

.OUTPUTS
    Displays the list of classic administrators in the console, including:
    - Subscription Name
    - Subscription ID
    - Administrator Sign-In Name

.NOTES
    - Ensure you have the necessary permissions to access Azure subscriptions and retrieve role assignments.
    - The script uses the Azure PowerShell module. Ensure it is installed and updated.
    - The script excludes specific subscription types based on their names.

.EXAMPLE
    Run the script to retrieve and display classic administrators:
    ```powershell
    .\Find-ClassicAdmins.ps1
    ```

    Output:
    ```
    # List of Classic Administrators:
    Subscription: ExampleSubscription - 12345678-1234-1234-1234-123456789abc
    Classic Administrator: admin@example.com
    ```

    If no classic administrators are found:
    ```
    # No classic administrators found in any subscription
    ```

#>
## Variables

# Time, colors, and formatting
Set-PSBreakpoint -Variable currenttime -Mode Read -Action {$global:currenttime = Get-Date -Format "dddd MM/dd/yyyy HH:mm"} | Out-Null
$foregroundColor1 = "Green"
$foregroundColor2 = "Yellow"
$writeEmptyLine = "`n"
$writeSeperatorSpaces = " - "

## Remove the breaking change warning messages

Set-Item -Path Env:\SuppressAzurePowerShellBreakingChangeWarnings -Value $true | Out-Null
Update-AzConfig -DisplayBreakingChangeWarning $false | Out-Null
$warningPreference = "SilentlyContinue"

## Write script started

Write-Host ($writeEmptyLine + "# Script started. Without errors, it might take some minute to complete" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor1 $writeEmptyLine

## Get all Azure subscriptions and store them in a variable

$subscriptions = Get-AzSubscription | Where-Object { $_.Name -NotMatch 'Microsoft Azure Enterprise' -and $_.Name -NotMatch 'Visual Studio'}

## Get and list all Azure classic subscription administrators for each subscription

$classicAdminsList = @()

foreach ($sub in $subscriptions) {
    Set-AzContext -SubscriptionId $sub.Id | Out-Null
    $classicAdmins = Get-AzRoleAssignment -IncludeClassicAdministrators | Where-Object {$_.RoleDefinitionName -like "*ServiceAdministrator*" -or $_.RoleDefinitionName -like "*CoAdministrator*"}
    if ($classicAdmins) {
        foreach ($admin in $classicAdmins) {
            $classicAdminsList += [PSCustomObject]@{
                SubscriptionName = $sub.Name
                SubscriptionId   = $sub.Id
                AdminSignInName  = $admin.SignInName
            }
        }
    }
}

## Display the list of classic administrators if any are found

if ($classicAdminsList.Count -gt 0) {
    Write-Host ($writeEmptyLine + "# List of Classic Administrators:" + $writeSeperatorSpaces + $currentTime)`
    -foregroundcolor $foregroundColor2 $writeEmptyLine
    $classicAdminsList | ForEach-Object {
        Write-Host "Subscription: $($_.SubscriptionName) - $($_.SubscriptionId)"
        Write-Host "Classic Administrator: $($_.AdminSignInName)" -foregroundcolor $foregroundColor2
        Write-Host ""
    }
} else {
    Write-Host ($writeEmptyLine + "# No classic administrators found in any subscription" + $writeSeperatorSpaces + $currentTime)`
    -foregroundcolor $foregroundColor1 $writeEmptyLine
}

## Write script completed

Write-Host ("# Script completed" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor1 $writeEmptyLine
