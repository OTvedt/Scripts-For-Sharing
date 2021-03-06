Connect-AzAccount # -Tenant xxxxxxx 
$AllSubs = get-AzSubscription | Where-Object { $_.Name -NotMatch 'Visual Studio' -and $_.Name -NotMatch 'Free' }
$CollectionAll = @(
  Foreach ($Sub in $AllSubs) {
    $AzSub = Select-AzSubscription -Subscription $Sub.Id -ErrorAction SilentlyContinue -WarningAction SilentlyContinue # -Tenant xxxxxxxxxxxxxxx
    $AzNw = Get-AZNetworkWatcher -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
    foreach ($Watcher in $AzNw) {
      [PSCustomObject]@{
        Subscription           = $AzSub.Name;
        SubscriptionId         = $AzSub.Subscription;
        NetworkWatcher         = $Watcher.Name
        NetworkWatcherLocation = $Watcher.Location
      }
    }
  }
)
$CollectionAll | Select-Object -Property Subscription, NetworkWatcherLocation | Sort-Object -Property Subscription, NetworkWatcherLocation | Format-Table -AutoSize
