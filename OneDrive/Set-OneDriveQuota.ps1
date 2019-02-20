# Setting new Quota on exsisting users are easy, information here: Using the https://docs.microsoft.com/en-us/onedrive/change-user-storage
# Doing this with an input file makes it more flexible. I have used the SharePoint Migration Tool's input file as the source since this makes me able to combine one input file with the migration itself.
# But any CSV file with the users site can be used (4 column in the SMT CSV file are used)

$Global:FilePath = "C:\Tools\" #Path to csv file
$Global:CsvName = "User-Info.csv" # Name of csv file
$Global:Csv = $Global:FilePath + $Global:CsvName
$Global:sSPOAdminCenterUrl = "https://<YourDomain>-admin.sharepoint.com" # URL to SharePoint admin center https://<Domain>-admin.sharepoint.com"
$csvItems = import-csv $Csv -Header c1,c2,c3,c4,c5,c6

Connect-SPOService -Url $sSPOAdminCenterUrl 

foreach ($item in $csvItems)
{

    Write-Host
    $OrgQuota = Get-SPOSite -Identity $Item.c4 -Detailed | select Owner,StorageQuota
    $OrgQuotaInGB=[math]::Round($OrgQuota.StorageQuota/1024)
    Write-Host "$($OrgQuota.Owner) Quota before change - $($OrgQuotaInGB) GB" 
    Set-SPOSite -Identity $Item.c4 -StorageQuota 25600 # size in MB 
    $NewQuota = Get-SPOSite -Identity $Item.c4 -Detailed | select Owner,StorageQuota
    $NewQuotaInGB=[math]::Round($NewQuota.StorageQuota/1024)
    Write-Host "$($OrgQuota.Owner) Quota after change - $($NewQuotaInGB) GB"

}
