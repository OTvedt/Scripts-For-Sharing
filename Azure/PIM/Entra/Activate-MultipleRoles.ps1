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
 
# Getting assigned roles
Write-Host "Getting already assigned roles..."
$existingRoles = @{}
foreach ($existing in $existingRoles) {
        $existingRole= Get-MgRoleManagementDirectoryRoleAssignment -Filter "principalId eq '$($user.Id)'"
        $existingRoles = $existingRole.RoleDefinitionId
    }
 
 
# Get roledefinitions based på RoleDefinitionId
Write-Host "Getting detales for rolledefinisjons..."
$roleDefinitions = @{}
$roleDefinitionId = @{}
foreach ($assignment in $eligibleAssignments) {
    if (-not $roleDefinitions.ContainsKey($assignment.RoleDefinitionId)) {
        $roleDefinition = Get-MgRoleManagementDirectoryRoleDefinition -UnifiedRoleDefinitionId $assignment.RoleDefinitionId
        $roleDefinitions[$assignment.Id] = $roleDefinition.DisplayName
    }
}

# Let user select length (default 8)
$h = Read-Host "`nFor how many hour should the role(s) be activated?`n(Select between 1-8, empty = 8 hour)"
if (-not $h -or $h -lt 1 -or $h -gt 8) {
    $h = 8
}

# Show available roles and let the user select
Write-Host "`nSelect the roles you want to activate `n"
$eligibleAssignments | ForEach-Object -Begin { $i = 0 } -Process {
    $i++
    $finnes = $false
    $roleDisplayName = $roleDefinitions[$_.Id] ? $roleDefinitions[$_.Id] : "(Unknown role name)"
    foreach ($role in $existingRoles) {
    #Write-Host "ExistingRoles: " $role
    #Write-Host "eligibleAssignments: " $eligibleAssignments[$i-1].RoleDefinitionId
        if ($existingRoles -eq $eligibleAssignments[$i-1].RoleDefinitionId) {
            $finnes = $true
        } else {
            $finnes = $false
      }
    }
    If ($finnes) {
        Write-Host "[$i] $roleDisplayName" -ForegroundColor Green
        } else {
            Write-Host "[$i] $roleDisplayName" -ForegroundColor Blue
         }
}

# Read the selection and convert it to a list of roles
Write-Host "`n"
$selectedIndexes = Read-Host "Type in number of the role.`nSeperated with comma if you will activate multiple roles"
$selectedIndexes = $selectedIndexes -split "," | ForEach-Object { $_.Trim() -as [int] }
 
# Hent de valgte rollene basert på brukerens valg
$roles = @()
for ($i = 0; $i -lt $selectedIndexes.Length; $i++) {
    $index = $selectedIndexes[$i] - 1
    if ($index -ge 0 -and $index -lt $eligibleAssignments.Count) {
        $roles += $roleDefinitions[$eligibleAssignments[$index].Id]
    }
}
 
Write-Output "Activating Entra roles for: "$MgContext.Account""
 
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
    Write-Output "Activated Entra role: "$role""
}
 
pause
