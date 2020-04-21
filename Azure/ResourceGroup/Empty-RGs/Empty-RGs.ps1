Login-AzAccount

$Subs = Get-AzSubscription | Where-Object {$_.Name -NotMatch 'Visual Studio' -and $_.Name -NotMatch 'Free'}
$AllEmptyResourceGroups = @()

ForEach ($sub in $Subs) {
    Select-AzSubscription -SubscriptionId $Sub.ID
    $AllRGs = Get-AzResourceGroup
    $UsedRGs = (Get-AzResource | Group-Object ResourceGroupName).Name
    $EmptyRGs = $AllRGs | Where-Object {$_.ResourceGroupName -notin $UsedRGs}

    foreach ($ActiveRG in $EmptyRGs) {
        $emptyRgItem = "" | select Name, Subscription, TagsOwner, TagsApplication
        $emptyRgItem.Name = $ActiveRG.ResourceGroupName
        $emptyRgItem.Subscription = $Sub.Name
        
            if ($ActiveRG.Tags.Owner -ne $null) {
                $emptyRgItem.TagsOwner = $ActiveRG.Tags.Owner
            }
            if ($ActiveRG.Tags.owner -ne $null) {
                $emptyRgItem.TagsOwner = $ActiveRG.Tags.owner
            }
            if ($ActiveRG.Tags.application -ne $null) {
                $emptyRgItem.TagsApplication = $ActiveRG.Tags.application
            }
            if ($ActiveRG.Tags.Application -ne $null) {
                $emptyRgItem.TagsApplication = $ActiveRG.Tags.Application
            }     

        $AllEmptyResourceGroups = $AllEmptyResourceGroups + $emptyRgItem 
    }
}
$AllEmptyResourceGroups | export-csv c:\temp\EmptyRG.csv -Delimiter ";" -NoTypeInformation
