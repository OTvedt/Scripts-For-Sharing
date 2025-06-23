# Requires: AzureAD or Microsoft.Graph PowerShell module
# This script lists all Entra (Azure AD) applications with secrets expiring with more than 2 years from today.
# It outputs two tables: one for secrets expiring in the year 2100 or later, and one for the rest (but still >2 years from today).

Connect-MgGraph -Scopes "Application.Read.All"

$futureDate = (Get-Date).AddYears(2)
$year2100 = Get-Date "2100-01-01"

$apps = Get-MgApplication -All

$results2100Plus = @()
$results2YearsPlus = @()

foreach ($app in $apps) {
    foreach ($pw in $app.PasswordCredentials) {
        $endDate = $pw.EndDateTime
        if ($endDate -ge $futureDate) {
            $obj = [PSCustomObject]@{
                AppDisplayName = $app.DisplayName
                AppId          = $app.AppId
                SecretName     = $pw.DisplayName
                SecretEndDate  = $endDate
            }
            if ($endDate -ge $year2100) {
                $results2100Plus += $obj
            } else {
                $results2YearsPlus += $obj
            }
        }
    }
}

Write-Host "`n=== Secrets expiring in 2100 or later ===" -ForegroundColor Cyan
$results2100Plus | Sort-Object SecretEndDate | Format-Table -AutoSize

Write-Host "`n=== Secrets expiring more than 2 years from today but before 2100 ===" -ForegroundColor Cyan
$results2YearsPlus | Sort-Object SecretEndDate | Format-Table -AutoSize
