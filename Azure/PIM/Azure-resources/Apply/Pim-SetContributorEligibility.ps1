# Import groups/users from csv and set them as eligibil. Remove them from active
Set-AzContext -Subscription spv-prod-01
$Csv = 'C:\Git\Azure\PIM\AzureResources\contributors.csv'
$csvItems = import-csv $Csv -Delimiter ';' -Header Group, Path
$Roledef = 'subscriptions/{Add your subscriptionID here}/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c' #Contributor
$Runs = 0

ForEach ($Item in $csvItems) {
    $Group = Get-AzADGroup -DisplayName $Item.Group
    $Path = $Item.Path
    $guid = New-Guid
    $startTime = Get-Date -Format o 
    $User = Get-AzADGroup -DisplayName 'G_Systemutvikling_TeamBM'
    $Runs++
    try {
        write  $Path $Group.DisplayName
        New-AzRoleEligibilityScheduleRequest -Name $guid -Scope $Path  -ExpirationType 'NoExpiration' -ExpirationDuration 'PT8H' -PrincipalId $Group.Id -RequestType AdminAssign -RoleDefinitionId $Roledef -ScheduleInfoStartDateTime $startTime
        Remove-AzRoleAssignment -Scope $Path -ObjectId $Group.Id -RoleDefinitionName Contributor
        Write-Output "$Runs of $($csvItems.count)"
    }
    catch {
        $_.Exception
        Pause
    }
}
