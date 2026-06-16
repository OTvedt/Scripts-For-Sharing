[CmdletBinding()]
param(
    [Parameter()]
    [ValidateRange(1, 8)]
    [int]$Hours = 8,

    [Parameter()]
    [string]$Justification = "Automated activation via Microsoft Graph",

    [Parameter()]
    [string[]]$RoleNames
)

$requiredModules = @(
    'Microsoft.Graph.Authentication'
    'Microsoft.Graph.Users'
    'Microsoft.Graph.Identity.Governance'
)

$missingModules = foreach ($moduleName in $requiredModules) {
    if (-not (Get-Module -ListAvailable -Name $moduleName)) {
        $moduleName
    }
}

if ($missingModules) {
    $moduleList = $missingModules -join ', '
    $installPrompt = Read-Host "The following required module(s) are not installed: $moduleList. Install now? (Y/N)"

    if ($installPrompt -match '^(?i)y(?:es)?$') {
        foreach ($moduleName in $missingModules) {
            Install-Module -Name $moduleName -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
        }
    }
    else {
        throw "Required module(s) not installed: $moduleList"
    }
}

$scopes = @(
    "RoleEligibilitySchedule.ReadWrite.Directory"
    "RoleAssignmentSchedule.ReadWrite.Directory"
    "RoleManagement.Read.Directory"
)

function Get-ScopeDisplayName {
    param(
        [Parameter()]
        [string]$DirectoryScopeId
    )

    if ([string]::IsNullOrWhiteSpace($DirectoryScopeId) -or $DirectoryScopeId -eq '/') {
        return 'Directory'
    }

    if ($DirectoryScopeId.Length -le 40) {
        return $DirectoryScopeId
    }

    return ('{0}...' -f $DirectoryScopeId.Substring(0, 37))
}

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

    $menu = foreach ($assignment in $eligibleAssignments) {
        $scopeDisplayName = Get-ScopeDisplayName -DirectoryScopeId $assignment.DirectoryScopeId

        [pscustomobject]@{
            DisplayName      = if ($roleDefinitions.ContainsKey($assignment.RoleDefinitionId)) { $roleDefinitions[$assignment.RoleDefinitionId] } else { '(Unknown role name)' }
            RoleDefinitionId = $assignment.RoleDefinitionId
            DirectoryScopeId = $assignment.DirectoryScopeId
            ScopeDisplayName = $scopeDisplayName
            IsActive         = $existingRoleIds -contains $assignment.RoleDefinitionId
        }
    } | Sort-Object IsActive, DisplayName, ScopeDisplayName

    for ($i = 0; $i -lt $menu.Count; $i++) {
        $menu[$i] | Add-Member -NotePropertyName Index -NotePropertyValue ($i + 1)
    }

    if ($PSBoundParameters.ContainsKey('RoleNames')) {
        $selectedRoles = foreach ($roleName in $RoleNames) {
            $matchingRoles = @($menu | Where-Object { $_.DisplayName -eq $roleName })

            if (-not $matchingRoles) {
                throw "Role not found among eligible assignments: $roleName"
            }

            foreach ($matchingRole in $matchingRoles) {
                $matchingRole
            }
        } | Sort-Object DisplayName, ScopeDisplayName -Unique
    }
    else {
        if (-not $PSBoundParameters.ContainsKey('Hours')) {
            $inputHours = Read-Host "`nFor how many hours should the role(s) be activated?`n(Select between 1-8, empty = 8 hours)"
            if ($inputHours) {
                if ($inputHours -notmatch '^\d+$' -or [int]$inputHours -lt 1 -or [int]$inputHours -gt 8) {
                    throw "Hours must be a whole number between 1 and 8."
                }
                $Hours = [int]$inputHours
            }
        }

        $inactiveRoles = @($menu | Where-Object { -not $_.IsActive })
        $activeRoles = @($menu | Where-Object { $_.IsActive })

        Write-Host "`nSelect the roles you want to activate:`n"

        if ($inactiveRoles.Count -gt 0) {
            Write-Host "Inactive eligible roles:" -ForegroundColor Cyan
            foreach ($item in $inactiveRoles) {
                Write-Host "[$($item.Index)] $($item.DisplayName) [$($item.ScopeDisplayName)]" -ForegroundColor Blue
            }
            Write-Host ""
        }

        if ($activeRoles.Count -gt 0) {
            Write-Host "Already active roles:" -ForegroundColor Cyan
            foreach ($item in $activeRoles) {
                Write-Host "[$($item.Index)] $($item.DisplayName) [$($item.ScopeDisplayName)]" -ForegroundColor Green
            }
            Write-Host ""
        }

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
    }

    Write-Output "Activating Entra roles for: $($mgContext.Account)"

    foreach ($role in $selectedRoles) {
        if ($role.IsActive) {
            Write-Warning "Skipping already active role: $($role.DisplayName) [$($role.ScopeDisplayName)]"
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
            Scope       = $role.ScopeDisplayName
            Hours       = $Hours
            Status      = 'Activated'
            ActivatedAt = Get-Date
        }
    }
}
catch {
    Write-Error $_
}
