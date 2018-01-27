# Needed Modules
#   Install-Module SharePointPnPPowerShellOnline
#   Install-Module AzureAD

$urlbase = "https://<TENANTNAME>-my.sharepoint.com/personal/"
$SPOService = "https://<TENANTNAME>-admin.sharepoint.com/"
$UserCredential = Get-Credential

Import-Module SharepointPnPPowerShellOnline
Import-Module AzureAD
Connect-PnPOnline -Url $SPOService -Credential $UserCredential
Connect-AzureAD -Credential $UserCredential

$O365Users = Get-AzureADUser -All $true
$sites=@(foreach($O365User in $O365Users)
{
  if($O365User.AssignedLicenses.Count -ne 0)
  {
    $url=($($urlbase)+$($O365User.UserPrincipalName.Replace(".","_"))).Replace("@","_")
    $site=Get-PnPTenantSite -Url $url -ErrorAction SilentlyContinue
    if($site)
    {
      $site | Select-Object Title,Owner,Url,StorageUsage
    }
  }
})
$sites|Out-GridView
# To get it in a file format you can change last line to be - $sites|Export-Csv -Path C:\temp\OD4BUsage.csv -Delimiter ";"
