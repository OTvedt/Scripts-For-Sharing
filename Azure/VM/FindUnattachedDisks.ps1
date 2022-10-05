# Inspired by https://learn.microsoft.com/en-us/azure/virtual-machines/windows/find-unattached-disks
$Subs = Get-AzSubscription | Where-Object { $_.Name -NotMatch 'Visual Studio' -and $_.Name -NotMatch 'Gratis' -and $_.Name -notmatch 'Tilgang til Azure Active Directory' }
$md = @()
$tbl = foreach ( $Sub in $Subs ) {
    Set-AzContext -Subscription $Sub | Out-Null
    
    $managedDisks = Get-AzDisk

    foreach ($md in $managedDisks) {
        if ($md.ManagedBy -eq $null) { 

            [PSCustomObject]@{
                Subscription      = $sub.Name
                DiskName          = $md.Name
                ResourceGroupName = $md.ResourceGroupName
                TimeCreated       = $md.TimeCreated
                OsType            = $md.OsType
            }
            
        }     
    }
}

$tbl | Export-Csv -Encoding UTF8 -Path "c:\Temp\Disks\Unattached Disks-$((Get-Date).ToString('dd.MM.yyyy-hh-mm')).csv" -Delimiter ';' -NoTypeInformation
