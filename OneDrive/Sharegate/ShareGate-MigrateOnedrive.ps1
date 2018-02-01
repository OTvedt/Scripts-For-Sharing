param
(
  [Parameter(Mandatory=$false)]
  [string]$InputFile='C:\temp\CopyContent.csv', #Use parameter -InputFile or change this entry
  [Parameter(Mandatory=$false,ValueFromPipeline=$false,Position=1)]
  [ValidateNotNull()]
  [System.Management.Automation.PSCredential]
  [System.Management.Automation.Credential()]
  $SrcCredential=[System.Management.Automation.PSCredential]::Empty,
  [Parameter(Mandatory=$false,ValueFromPipeline=$false,Position=1)]
  [ValidateNotNull()]
  [System.Management.Automation.PSCredential]
  [System.Management.Automation.Credential()]
  $DstCredential=[System.Management.Automation.PSCredential]::Empty,
  [switch]$HideProgress
)

Import-Module Sharegate
if($srccredential -eq [System.Management.Automation.PSCredential]::Empty)
{
  $srccredential=Get-Credential -Message "Enter your source credential"
}
if($dstcredential -eq [System.Management.Automation.PSCredential]::Empty)
{
  $dstcredential=Get-Credential -Message "Enter your destination credential"
}

$percent1Complete=0
if(-not($HideProgress))
{
    Write-Progress -Activity "Get OneDrive for usage" -CurrentOperation "Connecting" -Id 1 -PercentComplete $percent1Complete -Status ("Working - $($percent1Complete)%");
}

$table = @(Import-Csv $InputFile -Delimiter ";" -Encoding UTF8)

$numRows = if($table -and $table -is [array]){$table.Count}else{0}
$i = 1

foreach ($row in $table)
{
  if(-not($HideProgress))
  {
    # Output the result of reading the Sql table
    Write-Progress -Activity "Get OneDrive for usage" -CurrentOperation "User $i of $numRows" -Id 1 -PercentComplete $percent1Complete -Status ("Working - $($percent1Complete)%");
  }

  $copysettings = New-CopySettings -OnContentItemExists IncrementalUpdate
  $srcsite = Connect-Site -Url $row.SourceSite -Credential $srccredential
  $dstsite = Connect-Site -Url $row.DestinationSite -Credential $dstcredential 

  $srclist = Get-List -Site $srcsite -Name "Documents"
  $dstlist = Get-List -Site $dstsite -Name "Documents"
  Copy-Content -SourceList $srclist -DestinationList $dstlist -CopySettings $copysettings
  $i++
  [int]$percent1Complete=($i/$numRows*100)
}
