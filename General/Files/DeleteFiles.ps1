# Created by Alexander Solaat Rødland and Olav Tvedt
# Easy way of deleting files based on an input file. Can be single file or a folder per line in the input file
# Using the c1 header referense to be able to use a input files with mutiple value (Colone1, Colone2 etc)
# Be aware of using the -recurse parameter can delete more than you want too, that's why it's commented out ;-)

$Global:FilePath = "C:\powershell\Filer\Delete-files\" #Path to csv file
$Global:CsvName = "delete-list.csv" # Name of csv file. Should be entire path to file/folder. If using just the name instead of full path everything matching will be deleted if -Recurse are used
$Global:Csv = $Global:FilePath + $Global:CsvName
$csvItems = import-csv $Csv -Header c1
    Write-Output "--------------------------" >> $FilePath\DeleteFiles.log
    Write-Output "Started Delete Process - $(Get-Date)" >> $FilePath\DeleteFiles.log
ForEach ($item in $csvItems.c1){
if (Test-Path $item) {
    Remove-Item $item -Force -ErrorAction Continue # -Recurse
    if (Test-Path $item) {
        Write-Output "Error! - Could not delete all files.Additonal steps neccessary on $($item)" >> $FilePath\DeleteFiles.log
    }
    else {
    Write-Output "Deleted $($item)" >> $FilePath\DeleteFiles.log
}
    }
        else {
    Write-Output "Information! $($item) Not excisting" >> $FilePath\DeleteFiles.log
    }
}
    Write-Output "Delete Process Ended - $(Get-Date)" >> $FilePath\DeleteFiles.log
