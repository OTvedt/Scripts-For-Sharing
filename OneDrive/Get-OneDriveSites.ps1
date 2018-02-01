#region Header
<#
.SYNOPSIS
Get list of OneDrive for Business sites in a tenant

.DESCRIPTION
Get list of OneDrive for Business sites in a tenant

.NOTES
Author: Tvedt, Olav (olav.tvedt@lumagate.com)
Script Status: Production (Draft|Test|Production|Deprecated)

History:
Date    Version    Author    Category (NEW | CHANGE | DELETE | BUGFIX)    Description
2018.01.18  1.20180118.1  Olav    NEW  First release
2018.01.29  1.20180129.1  Olav    CHANGE Bugfixes and new features


.EXAMPLE
PS C:\>$Credential=Get-Credential
PS C:\>.\Get-OneDrive4BSites.ps1 -AdminURI 'https://contoso-admin.sharepoint.com' -Credential $Credential

This example output the result to console

.EXAMPLE
PS C:\>.\Get-OneDrive4BSites.ps1 -AdminURI 'https://contoso-admin.sharepoint.com' -Credential $Credential -OutFile 'C:\Temp\OD4BSites.txt'

This example output the result to a log file

.EXAMPLE
PS C:\>.\Get-OneDrive4BSites.ps1 -AdminURI 'https://contoso-admin.sharepoint.com' -OutGridView

This example output the result to Grid View and asks for credentials

.PARAMETER TenaneName
Specifies the Tenant name of your organization's SPO service.

.PARAMETER Credential
Specifies the User account credentials for an Office 365 global admin in your organization.

.PARAMETER OutFile
Specifies the location where the list of MySites should be saved. If not specified, result will be in a Grid View or Console.

.PARAMETER OutGridView
Output result to a Grid View

.PARAMETER OutConsole
Output result to Console.

.PARAMETER HideProgress
Hide the progress as the script runs.
#>
#endregion Header
[CmdletBinding()]
param
(
  [Parameter(Mandatory=$false)]
  [ValidateNotNullOrEmpty()]
  [string]$TenantName='', # Please change this to your tenant name or add it as a parameter -TenantName 'Contoso'
  [Parameter(Mandatory=$false,ValueFromPipeline=$false,Position=1)]
  [ValidateNotNull()]
  [System.Management.Automation.PSCredential]
  [System.Management.Automation.Credential()]
  $Credential=[System.Management.Automation.PSCredential]::Empty,
  [Parameter(Mandatory=$false,ValueFromPipeline=$false,Position=2)]
  [string]$URLSuffix='',
  [string]$OutFile,
  [switch]$OutGridView,
  [switch]$OutConsole,
  [switch]$HideProgress
)
$AdminURI = "https://$TenantName-admin.sharepoint.com/"

if($Credential -eq [System.Management.Automation.PSCredential]::Empty)
{
  $Credential=Get-Credential
}

# Load assemblies
$null=[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SharePoint.Client')
$null=[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SharePoint.Client.Runtime')
$null=[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SharePoint.Client.UserProfiles')

# Create a sharepoint credential
$creds = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($Credential.UserName, $Credential.Password)

# Show progress
$percent1Complete=0
if(-not($HideProgress))
{
  Write-Progress -Activity "Get OneDrive for Business sites" -CurrentOperation "Connecting" -Id 1 -PercentComplete $percent1Complete -Status ("Working - $($percent1Complete)%");
}

# Add the path of the User Profile Service to the SPO admin URL, then create a new webservice proxy to access it
$proxyaddr=$AdminURI+'/_vti_bin/UserProfileService.asmx?wsdl'
$userProfileService=New-WebServiceProxy -Uri $proxyaddr -UseDefaultCredential $false
if($userProfileService)
{
    $userProfileService.Credentials=$creds

    # Set variables for authentication cookies
    $strAuthCookie = $creds.GetAuthenticationCookie($AdminURI)
    $uri = New-Object System.Uri($AdminURI)
    $container = New-Object System.Net.CookieContainer
    $container.SetCookies($uri, $strAuthCookie)
    $userProfileService.CookieContainer = $container

    # Sets the first User profile, at index -1
    $userProfileResult=$userProfileService.GetUserProfileByIndex(-1)
    $numProfiles = $userProfileService.GetUserProfileCount()
    $i = 1

    # As long as the next User profile is NOT the one we started with (at -1)...
    $sitelist=while($userProfileResult.NextValue -ne -1) 
    {
      if(-not($HideProgress))
      {
        # Output the result of reading the Sql table
        Write-Progress -Activity "Get OneDrive for Business sites" -CurrentOperation "Profile $i of $numProfiles" -Id 1 -PercentComplete $percent1Complete -Status ("Working - $($percent1Complete)%");
      }
      # Look for the Personal Space object in the User Profile and retrieve it
      # (PersonalSpace is the name of the path to a user's OneDrive for Business site. Users who have not yet created a 
      # OneDrive for Business site might not have this property set.)
      $Prop = $userProfileResult.UserProfile | Where-Object { $_.Name -eq 'PersonalSpace' }
      $personalSpace=''
      if($Prop -and $Prop.Values[0].Value)
      {
        $personalSpace=$AdminURI.trim('/').replace('-admin','-my')+$($Prop.Values[0].Value)+$URLSuffix
        $Prop = $userProfileResult.UserProfile | Where-Object { $_.Name -eq 'UserName' }
        $userName=''
        if($Prop -and $Prop.Values[0].Value)
        {
          $userName=$Prop.Values[0].Value
        }
        New-Object -TypeName PSObject -Property (@{'PersonalSpace'=$personalSpace; 'UserName'=$userName})
      }

      # And now we check the next profile the same way...
      $userProfileResult = $UserProfileService.GetUserProfileByIndex($userProfileResult.NextValue)
      $i++
      [int]$percent1Complete=($i/$numProfiles*100)
    }
    if($sitelist)
    {
      if($OutFile)
      {
        # Output to file
        $sitelist|Format-Table -AutoSize|Out-String -Width 4096|Out-File -FilePath $OutFile -Force
      }
      if($OutGridView)
      {
        # Output to Grid View
        $sitelist|Out-GridView -Title 'OneDrive for Business Sites'
      }
      elseif($OutConsole -or (-not($OutGridView) -and -not($OutFile)))
      {
        $sitelist
      }
    }
    else{'OneDrive for Business sites not found!'}
} else {'Unable to connect to OneDrive for Business web service proxy!'}
