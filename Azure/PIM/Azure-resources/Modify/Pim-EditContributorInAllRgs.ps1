# You need a configuration file like the example file "default-settings.json"
# Remeber that the token are valid for only 1 hour, if you gone use longer time split it up
# Example on spliting it up could be in the line "$RGs = Get-AzResourceGroup | Select -first 100" (combine with -Skip 100 the next time to continue after the first 100)
# My example check for 4 values, this can be easliy modified.
# An easier check can be "([string]::IsNullOrEmpty($value.LastModifiedDateTime))" if you just want to check if it have been modified

$token = $(az account get-access-token --resource https://management.azure.com --output tsv --query accessToken)
$header = @{ Authorization = "Bearer $token" }
$body = get-content 'C:\PIM\AzureResources\default-settings.json' -raw
Set-AzContext -SubscriptionName '{SubscriptionName}'
$RGs = Get-AzResourceGroup

$totalRGs = $RGs.Count
$Runs = 0
$MissingCont = 0
$errcount = 0
foreach ($RG in $RGs) {
    $Scope = $RG.ResourceId
    $PolicyId = Get-AzRoleManagementPolicyAssignment -Scope $Scope | Where-Object { $_.RoleDefinitionDisplayName -eq "Contributor" }     
    $PName = split-path $PolicyId.PolicyId -Leaf
        
    Write-Output "Current RG:" $RG.ResourceGroupName
    $Value = Get-AzRoleManagementPolicy -Scope $Scope -Name $PName
    $url = "https://management.azure.com/$($Value.id)?api-version=2020-10-01"
    if (($value.EffectiveRule | Where-Object {
                $_.id -eq 'Enablement_EndUser_Assignment' }).EnabledRule -notcontains 'MultiFactorAuthentication' -or ($value.EffectiveRule | Where-Object {
                $_.id -eq 'Enablement_Admin_Assignment' }).EnabledRule -notcontains 'MultiFactorAuthentication' -or ($value.EffectiveRule | Where-Object {
                $_.id -eq 'Expiration_Admin_Assignment' }).IsExpirationRequired -or ($value.EffectiveRule | Where-Object {
                $_.id -eq 'Expiration_Admin_Eligibility' }).IsExpirationRequired) {

        try {
            Invoke-RestMethod $url -Headers $header -Method Patch -Body $body -ContentType application/json
            Write "Contributor: Have now been updated"
            $MissingCont++             
        }
        catch {
            $_.Exception
            $errcount++
        }

    }
    else {
        Write "Contributor: Was already modified" 
    }   
    $Runs++
    Write-Output "$Runs of $totalRGs"
}
Write-Output "Totaly number of RG's gone through $Runs"
Write-Output "Missing contributor on $MissingCont"
Write-Output "Changes failed $errcount"
