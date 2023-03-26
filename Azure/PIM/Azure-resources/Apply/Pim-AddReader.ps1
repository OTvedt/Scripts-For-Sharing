# When users are moved from Active to Eiligible they might need to have reader access permanent (Active). 
# The input file are equal to contributors.csv file
Set-AzContext -Subscription {Your subscription name}
$Csv = 'C:\Git\Azure\PIM\AzureResources\readers.csv'
$csvItems = import-csv $Csv -Delimiter ';' -Header Group,RG

ForEach ($Item in $csvItems) {
    $User = Get-AzADGroup -DisplayName $Item.Group
    $RG = $Item.RG
    # Get-AzRoleAssignment -ResourceGroupName $RG | Where-Object { $_.RoleDefinitionName -eq "Reader" -and $_.DisplayName -eq $User.DisplayName }  | Select DisplayName, RoleDefinitionName
    New-AzRoleAssignment -ObjectId $User.Id -RoleDefinitionName Reader -ResourceGroupName $RG
}


# $Antall = 0
# ForEach ($Item in $csvItems) {
#    $User = Get-AzADGroup -DisplayName $Item.Group
#    $RG = $Item.RG
#    if (Get-AzRoleAssignment -ResourceGroupName $RG | Where-Object { $_.RoleDefinitionName -eq "Reader" -and $_.DisplayName -eq $User.DisplayName }  | Select DisplayName, RoleDefinitionName) {
#        $Antall++}
#       
#  
#    # New-AzRoleAssignment -ObjectId $User.Id -RoleDefinitionName Reader -ResourceGroupName $RG
#    }
#    Write $Antall "av " $csvItems.count
