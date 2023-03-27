# Can use parameter for role and subscription
# Runs with parallel to save time
#Requires -Version 7.0
Param(
    [string] $SubscriptionName = '{Your subscription Name}',
    [string] $Role = 'Contributor'
)
$token = $(az account get-access-token --resource https://management.azure.com --output tsv --query accessToken)
$header = @{Authorization = "Bearer $token" }
$body = get-content 'C:\Git\operations\operations\Azure\PIM\AzureResources\modify\default-settings.json' -raw
Set-AzContext -SubscriptionName $SubscriptionName | Out-Null
$RGs = Get-AzResourceGroup
$all = @()
$all += $Rgs | ForEach-Object  -Parallel {
    $RG = $_ 
    $test = [PSCustomObject]@{
        Name      = $RG.ResourceGroupName
        Modified  = $false
        Exception = $null
    }
    $Scope = $RG.ResourceId
    $PolicyId = Get-AzRoleManagementPolicyAssignment -Scope $Scope | Where-Object { $_.RoleDefinitionDisplayName -eq $using:Role }     
    $PName = split-path $PolicyId.PolicyId -Leaf
    $Value = Get-AzRoleManagementPolicy -Scope $Scope -Name $PName
    $url = "https://management.azure.com/$($Value.id)?api-version=2020-10-01"
    if (($value.EffectiveRule | Where-Object {
                $_.id -eq 'Enablement_EndUser_Assignment' }).EnabledRule -notcontains 'MultiFactorAuthentication' -or ($value.EffectiveRule | Where-Object {
                $_.id -eq 'Enablement_Admin_Assignment' }).EnabledRule -notcontains 'MultiFactorAuthentication' -or ($value.EffectiveRule | Where-Object {
                $_.id -eq 'Expiration_Admin_Assignment' }).IsExpirationRequired -or ($value.EffectiveRule | Where-Object {
                $_.id -eq 'Expiration_Admin_Eligibility' }).IsExpirationRequired) {

        try {
            Invoke-RestMethod $Url -Headers $($using:header) -Method Patch -Body $using:body -ContentType application/json
            $Test.Modified = $true           
        }
        catch {
            $_.Exception
            $test.Exception = $_.Exception
        }
    }
    $test
}
$all 
$all  | Export-Csv -Encoding UTF8 -Path "c:\Temp\PIM\$($SubscriptionName)-$($Role)-$((Get-Date).ToString('dd.MM.yyyy-hh-mm')).csv" -Delimiter ';' -NoTypeInformation
