# A script that collect all used roles for your Azure resources (Not Azure AD roles) and create an inventory of the use in all subscriptions.
# It excludes some subscriptons like Visual Studio etc. and creates one file for each subscription and one common for all subscriptions

Connect-AzureAD

$Subs = Get-AzSubscription | Where-Object { $_.Name -NotMatch 'Visual Studio' -and $_.Name -NotMatch 'Access to Azure Active Directory' }
$All = @()

ForEach ($sub in $Subs) {

    Set-AzContext -SubscriptionName $sub.Name
    $AIMCont = Get-AzRoleAssignment
    $roles = (Get-AzRoleAssignment).RoleDefinitionName | Select-Object -Unique | Sort-Object
    $tbl = foreach ($role in $roles) {

        #  foreach ($role in $roles) {
        $Assignments = $AIMCont | Where-Object { $_.RoleDefinitionName -eq "$role" }

        foreach ($Assignment in $Assignments) {
            
            switch -wildcard ($Assignment.scope) 
            {
                "*resourcegroup*" { $type = "ResourceGroup" }
                "*managementgroup*" { $type = "ManagementGroup" }
                Default { $type = "Subscription" }
            }

            [PSCustomObject]@{
                DisplayName        = $Assignment.DisplayName
                ObjectType         = $Assignment.ObjectType
                RoleDefinitionName = $Assignment.RoleDefinitionName
                Type               = $type
                Subscription       = $sub.Name
                Path               = if ($Assignment.Scope -eq "/") { "Root" } else { $Assignment.Scope | Split-Path -Leaf }
            }
        }
    } 

    $All += $tbl
    $tbl | Export-Csv -Encoding UTF8 -Path "c:\Temp\PIM\$($sub.Name)-Roles-$((Get-Date).ToString('dd.MM.yyyy-hh-mm')).csv" -Delimiter ';' -NoTypeInformation

}  

$All | Export-Csv -Encoding UTF8 -Path "c:\Temp\PIM\Allsubs-Roles-$((Get-Date).ToString('dd.MM.yyyy-hh-mm')).csv" -Delimiter ';' -NoTypeInformation -Append
$All | Where-Object {$_.Type -eq 'ResourceGroup' -and $_.ObjectType -eq 'Group' -and ($_.RoleDefinitionName -eq 'Owner' -or $_.RoleDefinitionName -eq 'Contributor')}  |Export-Csv -Encoding UTF8 -Path "c:\Temp\PIM\RGsNeedsModification-$((Get-Date).ToString('dd.MM.yyyy-hh-mm')).csv" -Delimiter ';' -NoTypeInformation -Append
