# This will crawl throug all Azure subscriptions to find the Roles that are in use and document it into a csv file
Connect-AzAccount
$Subs = Get-AzSubscription | Where-Object { $_.Name -NotMatch 'Visual Studio' -and $_.Name -NotMatch 'Free' }

ForEach ($Sub in $subs) {

    Set-AzContext -SubscriptionName $sub.Name

    $roles = Get-AzRoleAssignment | Select RoleDefinitionName,RoleDefinitionId | select * -Unique | Sort-Object -Property RoleDefinitionName
        
    $roles | Export-Csv -Encoding UTF8 -Path c:\Temp\PIM\$($sub.Name)-RolesInUse-$((Get-Date).ToString('dd.MM.yyyy-hh-mm')).csv -Delimiter ';' -NoTypeInformation

}
