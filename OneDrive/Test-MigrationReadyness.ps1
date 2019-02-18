$Global:FilePath = "C:\Tools\" #Path to csv file
$Global:CsvName = "User-Info.csv" # Name of csv file
$Global:LogfileLocation = "FileScanErrors" # Name of log filelocation
$Global:Csv = $Global:FilePath + $Global:CsvName
$Global:Script = "C:\Tools\Test-OneDrivePath.ps1" #Location of the test-ondrivepath.ps script can be downloaded from: https://github.com/OTvedt/Scripts-For-Sharing/blob/master/OneDrive/Test-OneDrivePath.ps1
$Global:parameters =' -Path $Item -OutFolder $FilePath\$LogfileLocation -ErrorsOnly' #Paramters used with the script remove -ErrorsOnly to include warnings
$Global:ScriptLine = $script + $parameters

$csvItems = import-csv $Csv -Header c1

   # Write-Output "--------------------------" >> $FilePath\Test-MigrationReadyness.log
   # Write-Output "Started Test-MigrationReadyness.ps1 Process - $(Get-Date)" >> $FilePath\Test-MigrationReadyness.log
   # Write-Output "Resultat are located in a subfolder of " >> $FilePath\Test-MigrationReadyness.log

Write-Output "Started checking folder readyness Process - $(Get-Date)" >> $FilePath\Test-MigrationReadyness.log

ForEach ($item in $csvItems.c1)
{

   Write-Output "Starting with $($item) - $(Get-Date)" >> $FilePath\Test-MigrationReadyness.log
   Invoke-Expression $ScriptLine
   Write-Output "Finsihed with $($item) - $(Get-Date)" >> $FilePath\Test-MigrationReadyness.log
   Write-Output "";"" >> $FilePath\Test-MigrationReadyness.log  
}

Write-Output "Ended checking folder readyness Process - $(Get-Date)" >> $FilePath\Test-MigrationReadyness.log
 Write-Output "";"" >> $FilePath\Test-MigrationReadyness.log
