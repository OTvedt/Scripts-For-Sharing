# Goes trough all subscriptions (with some exeptions) looking for Unknowns.
# Unknowns are usally removed groups and users that no longer exist, but it can also be guest invitations that have not (yet) been connected/accepted
# Documents all findings in csv file, removes the unknowns and documents whats have been removed on all subscriptions in a text file in the end

$Subs = Get-AzSubscription | Where-Object { $_.Name -NotMatch 'Visual Studio' -and $_.Name -NotMatch 'Free' -and $_.Name -notmatch 'Access to Azure Active Directory'}
$All = @()
ForEach ($sub in $Subs) {
    $filepath = "C:\Temp"
    $objtype = "Unknown"
    $filename = "$($sub.Name)-$objtype-$((Get-Date).ToString('dd.MM.yyyy-hh-mm')).csv"
    Set-AzContext -SubscriptionName $sub
    $unknowns = Get-AzRoleAssignment | Where-Object { $_.ObjectType.Equals($objtype) }
    if ($unknowns.count -ge 1) {
        Export-Csv -InputObject $unknowns -Encoding UTF8 -Path "$filepath\$filename" -NoTypeInformation -Delimiter ";"
       ForEach ($entry in $unknowns) {
            $object = $entry.ObjectId
            $roledef = $entry.RoleDefinitionName
            $rolescope = $entry.Scope
            Remove-AzRoleAssignment -ObjectId $object -RoleDefinitionName $roledef -Scope $rolescope -outvariable res
            $All = $All +$res
        }       
    }
    Add-Content -Value $All -Path "$filepath\Removed-$objtype-$((Get-Date).ToString('dd.MM.yyyy-hh-mm')).txt"
}
