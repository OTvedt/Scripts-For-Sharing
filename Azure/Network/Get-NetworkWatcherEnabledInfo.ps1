# Install-Module Az.Network -Scope CurrentUser -Force
Connect-AzAccount # -Tenant xxxxxxx 
Get-AzTenant
Get-AzContext
$AllSubs = get-AzSubscription | Where-Object { $_.Name -NotMatch 'Visual Studio' -and $_.Name -NotMatch 'Prøv gratis' -and $_.Name -NotMatch 'Tilgang til Azure Active Directory' -and $_.Name -NotMatch 'HaraldVS' }
$CollectionAll = @(
  Foreach ($Sub in $AllSubs) {
    $AzSub = Select-AzSubscription -Subscription $Sub.Id # -Tenant xxxxxxxxxxxxxxx
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
$CollectionAll | Select-Object -Property Subscription, NetworkWatcherLocation | Sort-Object -Property Subscription, NetworkWatcherLocation