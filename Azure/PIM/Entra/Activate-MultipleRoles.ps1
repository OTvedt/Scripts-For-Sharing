Connect-MgGraph -Scope "RoleEligibilitySchedule.ReadWrite.Directory", "RoleAssignmentSchedule.ReadWrite.Directory", "RoleManagement.Read.Directory" -NoWelcome
 
$justification = "Automated activation via Microsoft Graph"
$MgContext = Get-MgContext
$User = Get-MgUser -UserId $MgContext.account

# Get all Eligible assignments
Write-Host "Getting all Eligible role assignments..."
$eligibleAssignments = Get-MgRoleManagementDirectoryRoleEligibilityScheduleInstance -Filter "principalId eq '$($user.Id)'"
 
if (-not $eligibleAssignments) {
    Write-Host "There are no Eligible role assignments found for the user."
    return
}
 
# Get already active role assignments
Write-Host "Getting already active roles..."
$activeAssignments = Get-MgRoleManagementDirectoryRoleAssignment -Filter "principalId eq '$($user.Id)'"
$existingRoles = $activeAssignments | Select-Object -ExpandProperty RoleDefinitionId

# Get role definitions based on RoleDefinitionId
Write-Host "Getting role definition details..."
$roleDefinitions = @{}
foreach ($assignment in $eligibleAssignments) {
    if (-not $roleDefinitions.ContainsKey($assignment.RoleDefinitionId)) {
        $roleDefinition = Get-MgRoleManagementDirectoryRoleDefinition -UnifiedRoleDefinitionId $assignment.RoleDefinitionId
        $roleDefinitions[$assignment.RoleDefinitionId] = $roleDefinition.DisplayName
    }
}

# Let user select duration (default 8)
$h = Read-Host "`nFor how many hours should the role(s) be activated?`n(Select between 1-8, empty = 8 hours)"
if (-not $h -or $h -lt 1 -or $h -gt 8) {
    $h = 8
}

# Show available roles and let the user select
Write-Host "`nSelect the roles you want to activate `n"
$eligibleAssignments | ForEach-Object -Begin { $i = 0 } -Process {
    $i++
    if ($roleDefinitions.ContainsKey($_.RoleDefinitionId)) {
        $roleDisplayName = $roleDefinitions[$_.RoleDefinitionId]
    } else {
        $roleDisplayName = "(Unknown role name)"
    }
    $finnes = $existingRoles -contains $_.RoleDefinitionId
    If ($finnes) {
        Write-Host "[$i] $roleDisplayName" -ForegroundColor Green
        } else {
            Write-Host "[$i] $roleDisplayName" -ForegroundColor Blue
         }
}

# Read the selection and convert it to a list of roles
Write-Host "`n"
$selectedIndexes = Read-Host "Type in the number of the role.`nSeparate with comma to activate multiple roles"
$selectedIndexes = $selectedIndexes -split "," | ForEach-Object { $_.Trim() -as [int] }
 
# Hent de valgte rollene basert på brukerens valg
$roles = @()
for ($i = 0; $i -lt $selectedIndexes.Length; $i++) {
    $index = $selectedIndexes[$i] - 1
    if ($index -ge 0 -and $index -lt $eligibleAssignments.Count) {
        $roles += $roleDefinitions[$eligibleAssignments[$index].RoleDefinitionId]
    }
}
 
Write-Output "Activating Entra roles for: $($MgContext.Account)"
 
foreach ($role in $roles) {
    $myRoles = Get-MgRoleManagementDirectoryRoleEligibilitySchedule -ExpandProperty RoleDefinition -All -Filter "principalId eq '$($user.Id)'"
    $myRoleName = $myroles | Select-Object -ExpandProperty RoleDefinition | Where-Object { $_.DisplayName -eq $role }
    $myRoleNameid = $myRoleName.Id
    $myRole = $myroles | Where-Object { $_.RoleDefinitionId -eq $myRoleNameid }
    $params = @{
        Action           = "selfActivate"
        PrincipalId      = $User.Id
        RoleDefinitionId = $myRole.RoleDefinitionId
        DirectoryScopeId = $myRole.DirectoryScopeId
        Justification    = $justification
        ScheduleInfo     = @{
            StartDateTime = Get-Date
            Expiration    = @{
                Type     = "AfterDuration"
                Duration = "PT${h}H"
            }
        }
    }
    New-MgRoleManagementDirectoryRoleAssignmentScheduleRequest -BodyParameter $params
    Write-Output "Activated Entra role: $role"
}
 
pause
