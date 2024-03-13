$Subs = Get-AzSubscription | Where-Object { $_.Name -NotMatch 'Visual Studio' -and $_.Name -NotMatch 'Free' }
$servicePrincipals = Get-AzADServicePrincipal
$AllSPs = $Subs | ForEach-Object {
    $sub = $_
    Set-AzContext -SubscriptionName $sub.Name | Out-Null

    $servicePrincipals| ForEach-Object -Parallel {
        $sp = $_
        $roleAssignments = Get-AzRoleAssignment -ObjectId $sp.Id
        if ($roleAssignments.Count -gt 0) {
            Write-Host "Found $($roleAssignments.Count) role assignments for service principal $($sp.DisplayName)"
# Signing og gyldig secret

                $roleAssignments | ForEach-Object {
                    [PSCustomObject]@{
                        Subscription = $using:sub.Name
                        ServicePrincipalName = $sp.DisplayName
                        Role = $_.RoleDefinitionName
                        
                }
            }
        }
    }
}
$AllSPs  | Export-Csv -Encoding UTF8 -Path "c:\Temp\SP-Roles-$((Get-Date).ToString('dd.MM.yyyy-hh-mm')).csv" -Delimiter ';' -NoTypeInformation -Append
