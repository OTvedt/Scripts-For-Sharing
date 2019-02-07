#Import-Module Microsoft.SharePoint.MigrationTool.PowerShell (Documents\powershell\modules)
#Based on https://docs.microsoft.com/en-us/sharepointmigration/overview-spmt-ps-cmdlets
#Added Ownvership process to take ownership before migration and removing it after
#Version 1.0 - 07/02/2019 by Olav Tvedt Twitter: @olavtwitt
#csv format example:
#C:\Tools\Files\Demoscar,,,https://<tenantid>-my.sharepoint.com/personal/demoscar_<tenantid>_onmicrosoft_com,Documents,HomeFolder
#C:\Tools\Files\BrianJ,,,https://<tenantid>-my.sharepoint.com/personal/brianj_<tenantid>_onmicrosoft_com,Documents,HomeFolder
#

$Global:FilePath = "C:\Tools\" #Path to csv file
$Global:CsvName = "User-Info.csv" # Name of csv file
$Global:Csv = $Global:FilePath + $Global:CsvName
$Global:sSPOAdminCenterUrl = "https://<tenantid>-admin.sharepoint.com" # URL to SharePoint admin center https://<Domain>-admin.sharepoint.com"
$Global:AdminUserName = "Demolav@<tenantid>.onmicrosoft.com"
$Global:AdminPassWord = ConvertTo-SecureString -String "PASSWORD" -AsPlainText -Force #Not recommended solution security related, but this works for running it as a scheduled task
$Global:SPOCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Global:AdminUserName, $Global:AdminPassWord
$Global:WorkingFolder = "C:\Tools\Migration-Temp\"

Connect-SPOService -Url $sSPOAdminCenterUrl -Credential $SPOCredential
Register-SPMTMigration -SPOCredential $Global:SPOCredential -Force -MigrateOneNoteFolderAsOneNoteNoteBook 1 -SkipFilesWithExtension json -WorkingFolder $Global:WorkingFolder 

$csvItems = import-csv $Csv -Header c1,c2,c3,c4,c5,c6

    Write-Output "--------------------------" >> $FilePath\Set-SecondaryOwvnerODcsv.log
    Write-Output "Started Set-SecondaryOwvnerODcsv.ps1 Process - $(Get-Date)" >> $FilePath\Set-SecondaryOwvnerODcsv.log

ForEach ($item in $csvItems)
{
    Set-SPOUser -Site $item.c4  -LoginName $Global:AdminUserName -IsSiteCollectionAdmin $True -ErrorAction SilentlyContinue | Out-Null
    Write-Output "$(Get-Date) - Added $($Global:AdminUserName) as secondary admin to the site $($item.c4)" >> $FilePath\\Set-SecondaryOwvnerODcsv.log
    Write-Host $item.c1
    Add-SPMTTask -FileShareSource $item.c1 -TargetSiteUrl $item.c4 -TargetList $item.c5 -TargetListRelativePath $item.c6
}
    Write-Output "Ended Set-SecondaryOwvnerODcsv.ps1 Process - $(Get-Date)" >> $FilePath\Set-SecondaryOwvnerODcsv.log

Start-SPMTMigration

    Write-Output "--------------------------" >> $FilePath\Remove-SecondaryOwvnerODcsv.log
    Write-Output "Started Remove-SecondaryOwvnerODcsv.ps1 Process - $(Get-Date)" >> $FilePath\Remove-SecondaryOwvnerODcsv.log

ForEach ($item in $csvItems)
{
    Set-SPOUser -Site $item.c4  -LoginName $Global:AdminUserName -IsSiteCollectionAdmin $False -ErrorAction SilentlyContinue | Out-Null
    Write-Output "$(Get-Date) - Added $($Global:AdminUserName) as secondary admin to the site $($item.c4)" >> $FilePath\Remove-SecondaryOwvnerODcsv.log  
}
    Write-Output "Ended Remove-SecondaryOwvnerODcsv.ps1 Process - $(Get-Date)" >> $FilePath\Remove-SecondaryOwvnerODcsv.log
