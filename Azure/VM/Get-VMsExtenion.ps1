<#
.SYNOPSIS
    Retrieves and exports information about Azure VMs with a specific extension.

.DESCRIPTION
    This script retrieves all Azure subscriptions except those with specific names, 
    then iterates through each subscription to get all VMs and their extensions. 
    It filters the extensions to find those published by "Qualys" and collects 
    relevant information into an array. The collected data is then output to the console 
    in a table format and optionally exported to a CSV file.

.PARAMETER None
    This script does not take any parameters.

.NOTES
    Author: Olav Tvedt
    Date: 28/11/2024
    Version: 1.0

.EXAMPLE
    .\VMs-withExtension.ps1
    This example runs the script and outputs the VM extension data to the console 
    and exports it to a CSV file located at "C:\temp\VMExtensions.csv".

#>
# Get all subscriptions
$subscriptions = Get-AzSubscription | Where-Object { $_.Name -NotMatch 'Microsoft Azure Enterprise' -and $_.Name -NotMatch 'Visual Studio' -and $_.Name -NotMatch 'Free' -and $_.Name -notmatch 'Access to Azure Active Directory' }

# Array to store VM extension data
$extensionData = @()

# Loop through each subscription
foreach ($subscription in $subscriptions) {
    Write-Host "Processing subscription: $($subscription.Name)"
    Set-AzContext -SubscriptionId $subscription.Id

    # Get all VMs in the subscription
    $vms = Get-AzVM

    # Loop through each VM and get its extensions based on publisher (Qualys)
    foreach ($vm in $vms) {
        $extensions = Get-AzVMExtension -ResourceGroupName $vm.ResourceGroupName -VMName $vm.Name
        foreach ($extension in $extensions) {
            if ($extension.Publisher -eq "Qualys") {
                $extensionData += [PSCustomObject]@{
                    SubscriptionName = $subscription.Name
                    VMName           = $vm.Name
                    ResourceGroup    = $vm.ResourceGroupName
                    ExtensionName    = $extension.Name
                    Publisher        = $extension.Publisher
                    Version          = $extension.TypeHandlerVersion
                    ProvisioningState = $extension.ProvisioningState
                }
            }
        }
    }
}

# Output the data
$extensionData | Format-Table -AutoSize

# Optionally, export to CSV
$extensionData | Export-Csv -Path "C:\temp\VMExtensions.csv" -NoTypeInformation
