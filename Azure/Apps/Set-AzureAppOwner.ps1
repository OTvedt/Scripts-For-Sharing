#https://docs.microsoft.com/powershell/module/azuread/add-azureadapplicationowner?WT.mc_id=AZ-MVP-4020472
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
