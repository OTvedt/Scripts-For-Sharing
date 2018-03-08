# Microsoft article
# https://support.office.com/en-us/article/upload-on-premises-content-to-sharepoint-online-using-powershell-cmdlets-555049c6-15ef-45a6-9a1f-a1ef673b867c?

# Step 1: Install Sharepoint Online Management Shell : http://go.microsoft.com/fwlink/?LinkID=617148&clcid=0x409
# Step 2: Setup Working Directory
# Temporary package folder : 'C:\OneDrive-PSMigration\Temp-Pkg'
# Final package folder : 'C:\OneDrive-PSMigration\Final-Pkg' 

#Step 3: Determine your locations and credentials
$cred = (Get-Credential admin@<TENANT-NAME>.onmicrosoft.com) #Change <TENANT-NAME> to name of your tenant
$sourceFiles = '\\DC1\Files' 
$sourcePackage = 'C:\OneDrive-PSMigration\Temp-Pkg'     # Temp area, must be deleted after used or changed to unik loaction for every run
$targetPackage = 'C:\OneDrive-PSMigration\Final-Pkg'    # Temp area, must be deleted after used or changed to unik loaction for every run
$targetWeb = 'https:/<TENANT-NAME>-my.sharepoint.com/personal/admin_<TENANT-NAME>_onmicrosoft_com'  #Change to desired site
$targetDocLib = 'Documents’  #Change to desired location on site, be aware that localization of Sharepoint online will have different names on folders. In Norwegian you would here use "Dokumenter"

#Step 4: Create a new content package from an on-premises file share
New-SPOMigrationPackage -SourceFilesPath $sourceFiles -OutputPackagePath $sourcePackage -TargetWebUrl $targetWeb -TargetDocumentLibraryPath $targetDocLib -IgnoreHidden –ReplaceInvalidCharacters 

#Step 5: Convert the content package for your target site
$finalPackages = ConvertTo-SPOMigrationTargetedPackage -ParallelImport -SourceFilesPath $sourceFiles -SourcePackagePath $sourcePackage -OutputPackagePath $targetPackage -Credentials $cred -TargetWebUrl $targetWeb -TargetDocumentLibraryPath $targetDocLib 

#Step 6: Submit content to import (Minor error in the original document -SourcePackagePath should be $targetPackage not $spoPackagePath and -TargetWebUrl should be $targetWeb not $targetWebUrl
#Example 1:
# $job = Invoke-SPOMigrationEncryptUploadSubmit -SourceFilesPath $sourceFiles -SourcePackagePath $targetPackage -Credentials $cred -TargetWebUrl $targetWeb
#Example 2:
$jobs = $finalPackages | % {Invoke-SPOMigrationEncryptUploadSubmit -SourceFilesPath $_.FilesDirectory.FullName -SourcePackagePath $_.PackageDirectory.FullName -Credentials $cred -TargetWebUrl $targetWeb} 
