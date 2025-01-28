<#
.DESCRIPTION
    List all Eligible roles for the user and allow activation of multiple roles
.AUTHOR
    Olav Tvedt
    https://www.youtube.com/@bluescreenbrothers
#>
Connect-MgGraph -Scope "RoleEligibilitySchedule.ReadWrite.Directory", "RoleAssignmentSchedule.ReadWrite.Directory" -NoWelcome

$justification = "Automated activation via Microsoft Graph"
$MgContext = Get-MgContext
$User = Get-MgUSer -UserId $MgContext.account
$myRoles = Get-MgRoleManagementDirectoryRoleEligibilitySchedule -ExpandProperty RoleDefinition -All -Filter "principalId eq '$($user.Id)'"

# Get all Eligible assignments
Write-Host "Getting all Eligible role assignments..."
$eligibleAssignments = Get-MgRoleManagementDirectoryRoleEligibilityScheduleInstance -Filter "principalId eq '$($user.Id)'"
 
if (-not $eligibleAssignments) {
    Write-Host "There are no Eligible role assignments found for the user."
    return
}
 
# Get roledefinitions based på RoleDefinitionId
Write-Host "Getting detales for rolledefinisjons..."
$roleDefinitions = @{}
foreach ($assignment in $eligibleAssignments) {
    if (-not $roleDefinitions.ContainsKey($assignment.RoleDefinitionId)) {
        $roleDefinition = Get-MgRoleManagementDirectoryRoleDefinition -UnifiedRoleDefinitionId $assignment.RoleDefinitionId
        $roleDefinitions[$assignment.Id] = $roleDefinition.DisplayName
    }
}
 
# Show available roles and let the user select
Write-Host "Select the roles you want to activate (type in number(s) seperated with comma):"
$eligibleAssignments | ForEach-Object -Begin { $i = 0 } -Process {
    $i++
    $roleDisplayName = $roleDefinitions[$_.Id] ? $roleDefinitions[$_.Id] : "(Ukjent rolle navn)"
    Write-Host "[$i] $roleDisplayName"
}

# Read the selection and convert it to a list of roles
$selectedIndexes = Read-Host "Skriv inn tall separert med komma"
$selectedIndexes = $selectedIndexes -split "," | ForEach-Object { $_.Trim() -as [int] }
$roles = @()
for ($i = 0; $i -lt $selectedIndexes.Length; $i++) {
    $index = $selectedIndexes[$i] - 1
    if ($index -ge 0 -and $index -lt $eligibleAssignments.Count) {
        $roles += $roleDefinitions[$eligibleAssignments[$index].Id]
    }
}

Write-Output "Activating Entra roles for: "$MgContext.Account""

foreach ($role in $roles) {
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
                Duration = "PT4H"
            }
        }
    }
    New-MgRoleManagementDirectoryRoleAssignmentScheduleRequest -BodyParameter $params
    Write-Output "Activated Entra role: "$role""
}

pause # To see the result after running the script
