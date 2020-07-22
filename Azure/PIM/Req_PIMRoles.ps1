Import-Module AzureADPreview

Connect-AzureAD

$Global:TennantID = Get-AzureADTenantDetail | Select-Object -ExpandProperty ObjectId 
$Global:UserName = whoami.exe /UPN #Or add upn name of user "Dem.Olav@tvedt.one"
$Global:UserID = Get-AzureADUser -ObjectId $UserName | Select-Object  -ExpandProperty ObjectId

function Show-Menu
{
     param (
           [string]$Title = 'Select role to request'
     )
     Clear-Host
     Write-Host "================ $Title ================"
    
     Write-Host "1: Press '1' for Global Administrator."
     Write-Host "2: Press '2' for Security Administrator."
     Write-Host "3: Press '3' for Exchange Administrator."
     Write-Host "4: Press '4' for Teams Administrator."
     Write-Host "5: Press '5' for Intune Administrator."
     Write-Host "Q: Press 'Q' to quit."
}

do
{
     Show-Menu
     $Userinput = Read-Host "Please make a selection"
     switch ($Userinput)
     {
           '1' {
                Clear-Host
                'You chose Global Administrator'
                $RoleID = Get-AzureADMSPrivilegedRoleDefinition -ProviderId aadRoles -ResourceId $TennantID | Where-Object {$_.DisplayName -Match 'Global Administrator'} | Select-Object -ExpandProperty Id
                $schedule = New-Object Microsoft.Open.MSGraph.Model.AzureADMSPrivilegedSchedule
                  $schedule.Type = "Once"
                  $schedule.Duration="PT4H" #Change number 4 to the number of hourse wanted
                  $schedule.StartDateTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
                Open-AzureADMSPrivilegedRoleAssignmentRequest -ProviderId 'aadRoles' -ResourceId $TennantID -RoleDefinitionId $RoleID -SubjectId $UserID -Type 'UserAdd' -Schedule $schedule -AssignmentState 'Active' -reason "Request from Powershell"
           } '2' {
                Clear-Host
                'You chose Security Administrator'
                $RoleID = Get-AzureADMSPrivilegedRoleDefinition -ProviderId aadRoles -ResourceId $TennantID | Where-Object {$_.DisplayName -Match 'Security Administrator'} | Select-Object -ExpandProperty Id
                $schedule = New-Object Microsoft.Open.MSGraph.Model.AzureADMSPrivilegedSchedule
                  $schedule.Type = "Once"
                  $schedule.Duration="PT4H" #Change number 4 to the number of hourse wanted
                  $schedule.StartDateTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
                Open-AzureADMSPrivilegedRoleAssignmentRequest -ProviderId 'aadRoles' -ResourceId $TennantID -RoleDefinitionId $RoleID -SubjectId $UserID -Type 'UserAdd' -Schedule $schedule -AssignmentState 'Active' -reason "Request from Powershell"
           } '3' {
                Clear-Host
                'You chose Exchange Administrator'
                $RoleID = Get-AzureADMSPrivilegedRoleDefinition -ProviderId aadRoles -ResourceId $TennantID | Where-Object {$_.DisplayName -Match 'Exchange Service Administrator'} | Select-Object -ExpandProperty Id
                $schedule = New-Object Microsoft.Open.MSGraph.Model.AzureADMSPrivilegedSchedule
                  $schedule.Type = "Once"
                  $schedule.Duration="PT4H" #Change number 4 to the number of hourse wanted
                  $schedule.StartDateTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
                Open-AzureADMSPrivilegedRoleAssignmentRequest -ProviderId 'aadRoles' -ResourceId $TennantID -RoleDefinitionId $RoleID -SubjectId $UserID -Type 'UserAdd' -Schedule $schedule -AssignmentState 'Active' -reason "Request from Powershell"
            } '4' {
                Clear-Host
                'You chose Teams Administrator'
                $RoleID = Get-AzureADMSPrivilegedRoleDefinition -ProviderId aadRoles -ResourceId $TennantID | Where-Object {$_.DisplayName -Match 'Teams Service Administrator'} | Select-Object -ExpandProperty Id
                $schedule = New-Object Microsoft.Open.MSGraph.Model.AzureADMSPrivilegedSchedule
                  $schedule.Type = "Once"
                  $schedule.Duration="PT4H" #Change number 4 to the number of hourse wanted
                  $schedule.StartDateTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
                Open-AzureADMSPrivilegedRoleAssignmentRequest -ProviderId 'aadRoles' -ResourceId $TennantID -RoleDefinitionId $RoleID -SubjectId $UserID -Type 'UserAdd' -Schedule $schedule -AssignmentState 'Active' -reason "Request from Powershell"
            } '5' {
                Clear-Host
                'You chose Teams Administrator'
                $RoleID = Get-AzureADMSPrivilegedRoleDefinition -ProviderId aadRoles -ResourceId $TennantID | Where-Object {$_.DisplayName -Match 'Intune Service Administrator'} | Select-Object -ExpandProperty Id
                $schedule = New-Object Microsoft.Open.MSGraph.Model.AzureADMSPrivilegedSchedule
                  $schedule.Type = "Once"
                  $schedule.Duration="PT4H" #Change number 4 to the number of hourse wanted
                  $schedule.StartDateTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
                Open-AzureADMSPrivilegedRoleAssignmentRequest -ProviderId 'aadRoles' -ResourceId $TennantID -RoleDefinitionId $RoleID -SubjectId $UserID -Type 'UserAdd' -Schedule $schedule -AssignmentState 'Active' -reason "Request from Powershell"
           } 'q' {
                return
           }
     }
     pause
}
until ($Userinput -eq 'q')