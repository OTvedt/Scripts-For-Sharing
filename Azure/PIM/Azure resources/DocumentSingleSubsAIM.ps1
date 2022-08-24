# A script that collect all used roles for your Azure resources and create an inventory for 1 named subscriptions (Change the $Subs = value)
# It creates a file

Connect-AzureAD

$Subs = "<Your Subscription name>"
Set-AzContext -SubscriptionName $subs
$AIMCont = Get-AzRoleAssignment
$Assignment = @()

$roles = (Get-AzRoleAssignment).RoleDefinitionName | Select-Object -Unique | Sort-Object

$tbl = foreach ($role in $roles) {
    $Assignments = $AIMCont | Where-Object {$_.RoleDefinitionName -eq "$role"}
    foreach($Assignment in $Assignments) {
        switch -wildcard ($Assignment.scope) {
            "*resourcegroup*" { $type = "ResourceGroup" }
            "*managementgroup*" { $type = "ManagementGroup"}
            Default {  $type = "Subscription" }
        }
        [PSCustomObject]@{
            DisplayName = $Assignment.DisplayName
            ObjectType = $Assignment.ObjectType
            RoleDefinitionName = $Assignment.RoleDefinitionName
            Type = $type
            Subscription = "$subs"
            Path = if($Assignment.Scope -eq "/") {"Root"} else {$Assignment.Scope | Split-Path -Leaf}
        }
    }
}

$tbl | Export-Csv -Encoding UTF8 -Path "c:\Temp\PIM\$subs-Roles-$((Get-Date).ToString('dd.MM.yyyy-hh-mm')).csv" -Delimiter ';' -NoTypeInformation