[CmdletBinding()]
param(
    [Parameter()]
    [ValidateRange(1, 8)]
    [int]$Hours = 8,

    [Parameter()]
    [string]$Justification = "Automated activation via Microsoft Graph"
)

$scopes = @(
    "RoleEligibilitySchedule.ReadWrite.Directory"
    "RoleAssignmentSchedule.ReadWrite.Directory"
    "RoleManagement.Read.Directory"
)

try {
    Connect-MgGraph -Scope $scopes -NoWelcome -ErrorAction Stop
    $mgContext = Get-MgContext

    if (-not $mgContext -or -not $mgContext.Account) {
        throw "No Microsoft Graph context was established."
    }

    $user = Get-MgUser -UserId $mgContext.Account -ErrorAction Stop

    Write-Verbose "Getting eligible role assignments..."
    $eligibleAssignments = @(Get-MgRoleManagementDirectoryRoleEligibilityScheduleInstance -Filter "principalId eq '$($user.Id)'" -All -ErrorAction Stop)

    if (-not $eligibleAssignments) {
        Write-Warning "No eligible role assignments found for $($mgContext.Account)."
        return
    }

    Write-Verbose "Getting already active roles..."
    $activeAssignments = @(Get-MgRoleManagementDirectoryRoleAssignment -Filter "principalId eq '$($user.Id)'" -All -ErrorAction Stop)
    $existingRoleIds = @($activeAssignments | Select-Object -ExpandProperty RoleDefinitionId)

    Write-Verbose "Getting role definition details..."
    $roleDefinitions = @{}
    foreach ($assignment in $eligibleAssignments) {
        if (-not $roleDefinitions.ContainsKey($assignment.RoleDefinitionId)) {
            $roleDefinition = Get-MgRoleManagementDirectoryRoleDefinition -UnifiedRoleDefinitionId $assignment.RoleDefinitionId -ErrorAction Stop
            $roleDefinitions[$assignment.RoleDefinitionId] = $roleDefinition.DisplayName
        }
    }

    if (-not $PSBoundParameters.ContainsKey('Hours')) {
        $inputHours = Read-Host "`nFor how many hours should the role(s) be activated?`n(Select between 1-8, empty = 8 hours)"
        if ($inputHours) {
            if ($inputHours -notmatch '^\d+$' -or [int]$inputHours -lt 1 -or [int]$inputHours -gt 8) {
                throw "Hours must be a whole number between 1 and 8."
            }
            $Hours = [int]$inputHours
        }
    }

    $menu = for ($i = 0; $i -lt $eligibleAssignments.Count; $i++) {
        $assignment = $eligibleAssignments[$i]
        [pscustomobject]@{
            Index            = $i + 1
            DisplayName      = if ($roleDefinitions.ContainsKey($assignment.RoleDefinitionId)) { $roleDefinitions[$assignment.RoleDefinitionId] } else { '(Unknown role name)' }
            RoleDefinitionId = $assignment.RoleDefinitionId
            DirectoryScopeId = $assignment.DirectoryScopeId
            IsActive         = $existingRoleIds -contains $assignment.RoleDefinitionId
        }
    }

    Write-Host "`nSelect the roles you want to activate:`n"
    foreach ($item in $menu) {
        $color = if ($item.IsActive) { 'Green' } else { 'Blue' }
        Write-Host "[$($item.Index)] $($item.DisplayName)" -ForegroundColor $color
    }

    Write-Host ""
    $selection = Read-Host "Type in the number of the role.`nSeparate with comma to activate multiple roles"
    if (-not $selection) {
        throw "No roles were selected."
    }

    $selectedIndexes = $selection -split ',' |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ } |
        ForEach-Object {
            if ($_ -notmatch '^\d+$') {
                throw "Invalid selection: '$_'"
            }
            [int]$_
        } |
        Select-Object -Unique

    $selectedRoles = foreach ($index in $selectedIndexes) {
        $item = $menu | Where-Object { $_.Index -eq $index }
        if (-not $item) {
            throw "Selection out of range: $index"
        }
        $item
    }

    Write-Output "Activating Entra roles for: $($mgContext.Account)"

    foreach ($role in $selectedRoles) {
        if ($role.IsActive) {
            Write-Warning "Skipping already active role: $($role.DisplayName)"
            continue
        }

        $params = @{
            Action           = 'selfActivate'
            PrincipalId      = $user.Id
            RoleDefinitionId = $role.RoleDefinitionId
            DirectoryScopeId = $role.DirectoryScopeId
            Justification    = $Justification
            ScheduleInfo     = @{
                StartDateTime = Get-Date
                Expiration    = @{
                    Type     = 'AfterDuration'
                    Duration = "PT${Hours}H"
                }
            }
        }

        New-MgRoleManagementDirectoryRoleAssignmentScheduleRequest -BodyParameter $params -ErrorAction Stop | Out-Null

        [pscustomobject]@{
            User        = $mgContext.Account
            Role        = $role.DisplayName
            Hours       = $Hours
            Status      = 'Activated'
            ActivatedAt = Get-Date
        }
    }
}
catch {
    Write-Error $_
}
