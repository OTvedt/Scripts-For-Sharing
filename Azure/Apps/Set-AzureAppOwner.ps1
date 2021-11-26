#https://docs.microsoft.com/en-us/powershell/module/azuread/add-azureadapplicationowner?view=azureadps-2.0
Connect-AzureAD
$Owner = Get-AzureADUser -ObjectId Dummy@domain.com
$FilePath = "C:\Temp\" #Path to csv file
$CsvName = "App-list.csv" # Name of csv file
$Csv = $FilePath + $CsvName
$Applist = Get-Content $Csv

ForEach ($App in $Applist) {
    
    $AppName = (Get-AzureADApplication -Filter "DisplayName eq '$App'")
    Add-AzureADApplicationOwner -ObjectId $AppName.ObjectId -RefObjectId $Owner.ObjectId
}
