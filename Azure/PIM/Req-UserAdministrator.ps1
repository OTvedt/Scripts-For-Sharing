# REquirement: AzureADPreview (Install-Module -Name AzureADPreview -AllowClobber)

$UserName = whoami.exe /UPN #Or add upn name of user "Dem.Olav@tvedt.one"
Connect-AzureAD -AccountId $UserName
$TennantID = Get-AzureADTenantDetail | Select-Object -ExpandProperty ObjectId 
$RoleID = Get-AzureADMSPrivilegedRoleDefinition -ProviderId aadRoles -ResourceId $TennantID | Where-Object {$_.DisplayName -Match 'User Account Administrator'} | Select-Object -ExpandProperty Id
$UserName = whoami.exe /UPN #Or add upn name of user like "Dem.Olav@tvedt.one"
$UserID = Get-AzureADUser -ObjectId $UserName | Select-Object  -ExpandProperty ObjectId
$schedule = New-Object Microsoft.Open.MSGraph.Model.AzureADMSPrivilegedSchedule
                  $schedule.Type = "Once"
                  $schedule.Duration="PT4H" #Change number 4 to the number of hourse wanted
                  $schedule.StartDateTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
Open-AzureADMSPrivilegedRoleAssignmentRequest -ProviderId 'aadRoles' -ResourceId $TennantID -RoleDefinitionId $RoleID -SubjectId $UserID -Type 'UserAdd' -Schedule $schedule -AssignmentState 'Active' -reason "Tester from Powershell"

Pause