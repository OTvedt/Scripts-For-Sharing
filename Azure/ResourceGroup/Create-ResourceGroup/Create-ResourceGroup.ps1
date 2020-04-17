#https://docs.microsoft.com/en-us/powershell/module/az.resources/new-azresourcegroup?view=azps-3.5.0
#https://docs.microsoft.com/en-us/azure/role-based-access-control/tutorial-role-assignments-user-powershell
#Install-Module -Name Az

$FilePath = "C:\PowerShell\Azure\ResourceGroups\" #Path to csv file
$CsvName = "ResourceGroup-Input.csv" # Name of csv file
$Csv = $FilePath + $CsvName
$csvItems = import-csv $Csv -Header c1,c2,c3,c4,c5,c6 -Delimiter ';'  #c1=Subscription,c2=Resource group name,c3=Tag-Owner,c4=Tag-application,c5=Role-Read,c6=Role-Contributor
$MyLocation = "westeurope"


#Connect to Azure
Connect-AzAccount
 
$i=0
ForEach ($item in $csvItems)
{
    $i++
    if (
        [string]::IsNullOrWhiteSpace($item.c1) -or
        [string]::IsNullOrWhiteSpace($item.c2) -or
        [string]::IsNullOrWhiteSpace($item.c3) -or
        [string]::IsNullOrWhiteSpace($item.c4)
    ) {
        Write-Warning -Message "Found empty content in columns of row $i"
    }
    else {
        #Select subscription
        $null = Select-AzSubscription -Subscription $item.c1
        #Create Resource Group
        $null = New-AzResourceGroup -Name $item.c2 -Location $MyLocation -Tag @{Empty=$null; Owner=$item.c3; Application=$item.c4}    
        #Set Contributor role
        if ([string]::IsNullOrWhiteSpace($item.c6)) {
            Write-Warning -Message "Contributor role not specified for row $i"
        }
        else {
            $adGroup = Get-AzADGroup -DisplayName $item.c6
            if ([string]::IsNullOrEmpty($adGroup)) {
                Write-Warning -Message "Unable to find AD Group $($item.c6) that is specified as Contributor role for row $i"
            }
            else {
                $adGroupId = $adGroup.id
                New-AzRoleAssignment -ObjectId $adGroupID -RoleDefinitionName "Contributor" -ResourceGroupName $item.c2    
            }
        }
        #Set Monitoring Reader role
        if ([string]::IsNullOrWhiteSpace($item.c5)) {
            Write-Warning -Message "Monitoring Reader role not specified for row $i"
        }
        else {
            $adGroup = Get-AzADGroup -DisplayName $item.c5
            if ([string]::IsNullOrEmpty($adGroup)) {
                Write-Warning -Message "Unable to find AD Group $($item.c5) that is specified as Monitoring Reader role for row $i"
            }
            else {
                $adGroupId = $adGroup.id
                New-AzRoleAssignment -ObjectId $adGroupID -RoleDefinitionName "Monitoring Reader" -ResourceGroupName $item.c2    
            }
        }
    }
} 
