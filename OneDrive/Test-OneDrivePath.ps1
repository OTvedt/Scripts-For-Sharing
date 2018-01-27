#region Header
<#
.SYNOPSIS
Check if files and folders in a OneDrive library folder is possible to syncronize

.DESCRIPTION
This script can be used to check for inconsitensies in any folder, not just OneDrive library folders.
For a list of rules that files and folders must be compliant with look at:
https://support.microsoft.com/en-us/help/3125202/restrictions-and-limitations-when-you-sync-files-and-folders
https://support.microsoft.com/en-us/help/3034685/restrictions-and-limitations-when-you-sync-onedrive-for-business-files

.NOTES
Author: Johansen, Reidar (reidar.johansen@lumagate.com)
Script Status: Production (Draft|Test|Production|Deprecated)

History:
Date	Version	Author	Category (NEW | CHANGE | DELETE | BUGFIX)	Description
2017.09.13  1.20170913.1  Reidar  NEW  First release
2017.09.21  1.20170921.1  Reidar  BUGFIX  Improved error handling on Get-ChildItem etc.
2017.09.21  1.20170921.2  Reidar  CHANGE  Path variable no longer mandatory, defaults to current path
2017.09.21  1.20170921.3  Reidar  CHANGE  Added Warning conditions
2017.09.21  1.20170921.4  Reidar  CHANGE  Added ErrorsOnly switch
2017.09.26  1.20170926.1  Olav    CHANGE  Filetypes updated and modified for Ignite give away
2017.09.29  1.20170929.1  Reidar  CHANGE  Updated filetypes etc. to be in line with newer list of rules
2018.01.10  1.20180110.1  Reidar  BUGFIX  Updated BlockedFileCharactersAndStrings, changed  .+$ to ^ .+$
2018.01.11  1.20180111.1  Reidar  CHANGE  Added function Get-UserPermission and testing to check file/folder access

.EXAMPLE
PS C:\>.\Test-OneDrivePath.ps1 -Path 'H:\HomeDirs'

This example output the result to a grid view.
.EXAMPLE
PS C:\>.\Test-OneDrivePath.ps1 -Path 'H:\HomeDirs' -OutFile '.\notcompliant.txt'

This example output the result to a textfile.
.PARAMETER Path
Path to the OneDrive library folder.
.PARAMETER BlockedFileCharactersAndStrings
Characters and strings not valid in file name. Must be a regular expression.
.PARAMETER BlockedFilePrefixesAndExtensions
Invalid prefixes and extensions for a file name. Must be a regular expression.
.PARAMETER InvalidFoldernames
Folder names not valid. Must be a regular expression.
.PARAMETER InvalidRootFoldernames
Root folder names not valid. Must be a regular expression.
.PARAMETER NumberOfFilesLimit
Maximum number of files that should exist in folder and it's sub folders.
.PARAMETER FilepathLengthLimit
Maximum number of characters for a file path, including the filename, but excluding the base path where search start from.
.PARAMETER FileSizeLimitGB
Maximum size for a file in GB.
.PARAMETER WarningFileNames
Warning if file name matches this regular expression.
.PARAMETER WarningFileSizeLimitMB
Warning size for a file in MB.
.PARAMETER OutFile
Full path and filename where the result will be stored. If not specified, result will be in a Grid View.
.PARAMETER OutGridView
If not specified, result will be returned as object.
.PARAMETER ErrorsOnly
Only include errors.
#>
#endregion Header
#region Parameter
[CmdletBinding()]
param
(
  [Parameter(Mandatory=$false,ValueFromPipeline=$True,Position=0)]
  [string]$Path,
  [string]$BlockedFileCharactersAndStrings='#|%|<|>|:|"|\/|\\|\||\?|\*|^ .+$|.+ $|^\.|\.$|^~|~\$|\._|^CON$|^PRN$|^AUX$|^NUL$|^COM[1-9]$|^LPT[1-9]$|^_vti_$',
  [string]$BlockedFilePrefixesAndExtensions='\.ascx$|\.asmx$|\.aspx$|\.htc$|\.jar$|\.master$|\.swf$|\.xap$|\.xsf$|\.ashx$|\.json$|\.soap$|\.svc$|\.xamlx$|\.files$|\.one$|\.onepkg$|\.onetoc$|\.onetoc2$|_files$|_Dateien$|_fichiers$|_bestanden$|_file$|_archivos$|_filer$|_tiedostot$|_pliki$|_soubory$|_elemei$|_ficheiros$|_arquivos$|_dosyalar$|_datoteke$|_fitxers$|_failid$|_fails$|_bylos$|_fajlovi$|_fitxategiak$|\.laccdb$|\.tmp$|\.tpm$',
  [string]$InvalidFileTypes='^Thumbs\.db$|^EhThumbs\.db$|^Desktop\.ini$|^\.DS_Store$|^Icon$|^\.lock$',
  [string]$InvalidFoldernames='^_t$|^_w$|^_vti_$',
  [string]$InvalidRootFoldernames='^forms$',
  [int]$NumberOfFilesLimit=100000,
  [int]$FilepathLengthLimit=400,
  [int]$FileSizeLimitGB=15,
  [string]$WarningFileNames='\.exe$|\.hlp$|\.hta$|\.inf$|\.ins$|\.isp$|\.its$|\.js$|\.jse$|\.key$|\.mht$|\.msc$|\.msh$|\.msi$|\.msp$|\.mst$|\.nch$|\.ops$|\.pif$|\.prf$|\.prg$|\.pst$|\.reg$|\.scf$|\.scr$|\.shb$|\.shs$|\.url$|\.vb$|\.vbe$|\.vbs$|\.wmf$|\.ws$|\.wsc$|\.wsf$|\.wsh$',
  [int]$WarningFileSizeLimitMB=200,
  [string]$OutFile,
  [switch]$OutGridView,
  [switch]$ErrorsOnly
)
#endregion Parameter
Set-StrictMode -Version Latest;
#region Variables
#----------------------------------
# Variables - can change if needed
#----------------------------------
[string]$scriptVersion='1.20180111.1';

#----------------------------------
# Variables - do not change
#----------------------------------
$errorlist=@();
[string]$scriptUser=[System.Security.Principal.WindowsIdentity]::GetCurrent().Name;
[string]$scriptComputer=[System.Environment]::MachineName;
if(-not($Path)){$Path=(Resolve-Path .\).Path;};
$fileNumber=$folderNumber=$percent2Complete=0;
$foldersinpath=@($($Path.Split('\'))|Where-Object{$_ -ne ''}).Count;
#endregion Variables
#region Functions
function Get-OutMessage
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory=$false,Position=0)]
    $Name,
    [Parameter(Mandatory=$false,Position=1)]
    $FullName,
    [Parameter(Mandatory=$false,Position=2)]
    $Message,
    [Parameter(Mandatory=$false,Position=3)]
    [ValidateSet('Error','Warning')]
    $Status='Error',
    [Parameter(Mandatory=$false,Position=4)]
    [bool]$IsFolder=$false
  )
  New-Object PSObject -Property @{Status=$Status;Name=$Name;IsFolder=$IsFolder;FullName=$FullName;Message=$Message};
};
function Get-OutMessageFromError
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory=$false,Position=0)]
    $ErrorList,
    [Parameter(Mandatory=$true,Position=1)]
    [ValidateNotNullOrEmpty()]
    $Name,
    [Parameter(Mandatory=$false,Position=2)]
    [ValidateSet('Error','Warning')]
    $Status='Error',
    [Parameter(Mandatory=$false,Position=3)]
    [switch]$IsFolder
  )
  foreach($e in $ErrorList)
  {
    # Get error message
    $msg=$e.Exception.Message;
    $fullname='';
    # Replace known errors with better message
    if($msg -match 'Could not find a part of the path')
    {
      $fullname=$msg.Replace('Could not find a part of the path','').Trim('.').Trim().Trim("'");
      $msg='Path is too long.';
    };
    Get-OutMessage -Status $Status -Name $Name -IsFolder $IsFolder -FullName $fullname -Message $msg;
  };  
};
function Get-UserPermission
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory=$true,Position=0)]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Path -Path $_})]
    [string]$Path
  )
  if(Test-Path -Path $Path -PathType Leaf)
  {
    try
    {
      $filetest=[System.IO.File]::Open($Path,'Open','ReadWrite','None');
      $filetest.Close();
      $filetest.Dispose();
      'CanWrite';
    }
    catch
    {
      try
      {
        $filetest=[System.IO.File]::OpenRead($Path);
        $filetest.Close();
        $filetest.Dispose();
        'CanRead';
      }
      catch
      {
        $_.Exception.Message;        
      };
    };
  } else {
    try
    {
      $null=[System.IO.Directory]::GetFileSystemEntries($Path);
      'CanBrowse';
    }
    catch
    {
        $_.Exception.Message;        
    };
  };
};
#endregion Functions
#region Main
# Check that path is accessible
if(-not(Test-Path -Path $Path -PathType Container)){throw "Path is not valid: $Path";};
$pathtest=Get-UserPermission -Path $Path;
if($pathtest -ne 'CanBrowse'){throw $pathtest;};
# Get files in path
$files=@(Get-ChildItem -Path $Path -Recurse -File -ErrorAction SilentlyContinue -ErrorVariable getfileerrors);
# Check for errors during Get-ChildItem
$errorlist+=Get-OutMessageFromError -ErrorList $getfileerrors -Name 'Error on reading files.';
$numberoffiles=if($files -is [array]){$files.Count;}else{0;};
# Number of files should not exceed limit
if($numberoffiles -gt $NumberOfFilesLimit){$errorlist+=Get-OutMessage -Name $Path -FullName $Path -Message "Total number of files are $numberoffiles, this exceeds the recommended limit of $NumberOfFilesLimit files." -IsFolder $true;};
# Get folders in path
$folders=@(Get-ChildItem -Path $Path -Recurse -Directory -ErrorAction SilentlyContinue -ErrorVariable getfoldererrors);
# Check for errors during Get-ChildItem
$errorlist+=Get-OutMessageFromError -ErrorList $getfoldererrors -Name 'Error on reading folders.' -IsFolder;
$numberoffolders=if($folders -is [array]){$folders.Count;}else{0;};
# Check files in Path
foreach($file in $files)
{
  $fileNumber++;
  # Output progress
  Write-Progress -Activity "$($file.FullName)" -CurrentOperation "File number $fileNumber of $numberoffiles" -Id 1 -PercentComplete $percent2Complete -Status ("Checking files - $($percent2Complete)%");
  # File name must not contain blocked characters or strings
  if($file.Name -match $BlockedFileCharactersAndStrings){$errorlist+=Get-OutMessage -Name $file.Name -FullName $file.FullName -Message 'This file will be blocked due to invalid character(s) or string(s).';};
  # File name must not have blocked prefix or extension
  if($file.Name -match $BlockedFilePrefixesAndExtensions){$errorlist+=Get-OutMessage -Name $file.Name -FullName $file.FullName -Message 'This file will be blocked due to invalid prefix or extension.';};
  # Check if file name should be a warning
  if(-not($ErrorsOnly) -and $file.Name -match $WarningFileNames){$errorlist+=Get-OutMessage -Name $file.Name -FullName $file.FullName -Message 'This file may be unwanted for security reasons.' -Status Warning;};
  # Size of a file should not exceed size limit
  if($file.Length -gt ($FileSizeLimitGB * 1024 * 1024 * 1024)){$size=[math]::Round(($file.Length/1gb),2);$errorlist+=Get-OutMessage -Name $file.Name -FullName $file.FullName -Message "This file exceed the size limit of $FileSizeLimitGB GB. It is $size GB.";};
  # Size of a file should not exceed warning size limit
  if(-not($ErrorsOnly) -and $file.Length -gt ($WarningFileSizeLimitMB * 1024 * 1024)){$size=[math]::Round(($file.Length/1mb),2);$errorlist+=Get-OutMessage -Name $file.Name -FullName $file.FullName -Message "This file exceed the size limit of $WarningFileSizeLimitMB MB. It is $size MB." -Status Warning;};
  # File name paths should not be over 400 characters, we exclude root path
  $checkbasepath=$file.FullName.Replace($Path,'').Trim('\');
  if($checkbasepath.Length -gt $FilepathLengthLimit){$errorlist+=Get-OutMessage -Name $file.Name -FullName $file.FullName -Message "This file path use more than $FilepathLengthLimit characters. It has $($checkbasepath.Length) characters.";};
  # Only files with write permission and that is not open can be synced
  $filepermission=Get-UserPermission -Path $file.FullName;
  if($filepermission -ne 'CanWrite'){$errorlist+=Get-OutMessage -Name $file.Name -FullName $file.FullName -Message $filepermission;};
  # Calculate percentage completed for loop
  [int]$percent2Complete=if($numberoffiles){($fileNumber/$numberoffiles*100);}else{100;};
};
# Check folders in Path
$percent2Complete=0;
foreach($folder in $folders)
{
  $folderNumber++;
  # Output progress
  Write-Progress -Activity "$($folder.FullName)" -CurrentOperation "Folder number $folderNumber of $numberoffolders" -Id 1 -PercentComplete $percent2Complete -Status ("Checking folders - $($percent2Complete)%");
  # Folder name must not be invalid
  if($folder.Name -match $InvalidFoldernames){$errorlist+=Get-OutMessage -Name $folder.Name -FullName $folder.FullName -IsFolder $true -Message 'Invalid folder name.';};
  # Root folder name must not invalid
  $isrootfolder=if($($(@($folder.FullName.Split('\')).Count)-1) -le $foldersinpath){$true;}else{$false;};
  if($isrootfolder -and $folder.Name -match $InvalidRootFoldernames){$errorlist+=Get-OutMessage -Name $folder.Name -FullName $folder.FullName -IsFolder $true -Message 'Invalid root folder name.';};
  # Folder name paths should not be over 400 characters, we exclude root path
  $checkbasepath=$folder.FullName.Replace($Path,'').Trim('\');
  if($checkbasepath.Length -gt $FilepathLengthLimit){$errorlist+=Get-OutMessage -Name $folder.Name -FullName $folder.FullName -IsFolder $true -Message "This path is above the recommended limit of $FilepathLengthLimit characters. It has $($checkbasepath.Length) characters.";};
  # Only browsable folders can be synced
  $folderpermission=Get-UserPermission -Path $folder.FullName;
  if($folderpermission -ne 'CanBrowse'){$errorlist+=Get-OutMessage -Name $folder.Name -FullName $folder.FullName -Message $folderpermission;};
  # Calculate percentage completed for loop
  [int]$percent2Complete=if($numberoffolders){($folderNumber/$numberoffolders*100);}else{100;};
};
# Output result
if(-not($errorlist))
{
  'No issues found!'
}
elseif($OutFile)
{
  # Output to file
  $errorlist|Select-Object Status,Message,Name,FullName|Sort-Object Status,FullName|Format-Table -AutoSize|Out-String -Width 4096|Out-File -FilePath $OutFile -Force;
}
elseif($OutGridView)
{
  # Output to Grid View
  $errorlist|Select-Object Status,Message,Name,FullName|Sort-Object Status,FullName|Out-GridView -Title 'Files and folders that needs attention';
}
else
{
  $errorlist|Select-Object Status,Message,Name,FullName|Sort-Object Status,FullName;
};
#endregion Main
