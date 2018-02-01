#Info
<#
.SYNOPSIS
List the path, owner and size of OneDrive for business sites. Licensed users only

.DESCRIPTION
Check all licensed users that have and OneDrive for Business site.

.NOTES
To install needed modules
  Install-Module SharePointPnPPowerShellOnline
  Install-Module AzureAD

Author: Olav Tvedt
Script Status: Test (Draft|Test|Production|Deprecated)

History:
Date    Version    Author    Category (NEW | CHANGE | DELETE | BUGFIX)    Description
2018.01.27  1.20180127.1  Olav    NEW  First release

.EXAMPLE
PS C:\>.\Get-OneDriveUsage.ps1 -TenantName 'contoso' -OutGridView

This example asks for credentials and output the result to Grid View

.PARAMETER TenaneName
Specifies the Tenant name of your organization's SPO service.

.PARAMETER Credential
Specifies the User account for an Office 365 global admin in your organization.

.PARAMETER OutFile
Specifies the location where the list should be saved. If not specified, result will be in a Grid View or Console.

.PARAMETER OutGridView
Output result to a Grid View.

.PARAMETER OutConsole
Output result to Console.

.PARAMETER HideProgress
Hide the progress as the script runs.
#>
[CmdletBinding()]
param
(
  [Parameter(Mandatory=$true)]
  [String]$TenaneName,
  [Parameter(Mandatory=$false,ValueFromPipeline=$false,Position=1)]
  [ValidateNotNull()]
  [System.Management.Automation.PSCredential]
  [System.Management.Automation.Credential()]
  $Credential=[System.Management.Automation.PSCredential]::Empty,
  [string]$OutFile,
  [switch]$OutGridView,
  [switch]$OutConsole,
  [switch]$HideProgress
)
$urlbase = "https://$TenaneName-my.sharepoint.com/personal/"
$SPOService = "https://$TenaneName-admin.sharepoint.com/"

if($Credential -eq [System.Management.Automation.PSCredential]::Empty)
{
  $Credential=Get-Credential
}

Import-Module SharepointPnPPowerShellOnline
Import-Module AzureAD

# Show progress
$percent1Complete=0
if(-not($HideProgress))
{
  Write-Progress -Activity 'Get OneDrive Usage' -PercentComplete $percent1Complete -Status ("Working - $($percent1Complete)%")
}

Connect-PnPOnline -Url $SPOService -Credential $Credential
Connect-AzureAD -Credential $Credential

$O365Users = Get-AzureADUser -All $true
$numUsers = $O365Users.Count
$i = 1
$sites=@(foreach($O365User in $O365Users)
{
  if(-not($HideProgress))
  {
    # Output the result of reading the Sql table
    Write-Progress -Activity "Get OneDrive for usage" -CurrentOperation "User $i of $numUsers" -Id 1 -PercentComplete $percent1Complete -Status ("Working - $($percent1Complete)%");
  }
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
if($sites)
{
  if($OutFile)
  {
    # Output to file
    $sites|Export-Csv -Path $OutFile -Delimiter ';' -NoTypeInformation -Encoding UTF8 -Force 
  }
  if($OutGridView)
  {
    # Output to Grid View
    $site|Out-GridView -Title 'OneDrive for Business Usage'
  }
  elseif($OutConsole -or (-not($OutGridView) -and -not($OutFile)))
  {
    $sites
  }
}
else{'OneDrive for Business usage not found!'}
