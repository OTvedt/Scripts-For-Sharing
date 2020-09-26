# Fetches the last month's Azure Active Directory sign-in data
# Modified from https://petri.com/azuread-signin-powershell
Connect-AzureAD
CLS; $StartDate = (Get-Date).AddDays(-7); $StartDate = Get-Date($StartDate) -format yyyy-MM-dd  #Change .AddDays(-7) to another number if more or less days wanted
Write-Host "Fetching data from Azure Active Directory..."
$Records = Get-AzureADAuditSignInLogs -Filter "createdDateTime gt $StartDate" -all:$True  
$Report = [System.Collections.Generic.List[Object]]::new() 
ForEach ($Rec in $Records) {
    Switch ($Rec.Status.ErrorCode) {
      "0" {$Status = "Success"}
      default {$Status = $Rec.Status.FailureReason}
    }
    $ReportLine = [PSCustomObject] @{
           TimeStamp   = Get-Date($Rec.CreatedDateTime) -format g
           User        = $Rec.UserPrincipalName
           Name        = $Rec.UserDisplayName
           IPAddress   = $Rec.IpAddress
           ClientApp   = $Rec.ClientAppUsed
           Device      = $Rec.DeviceDetail.OperatingSystem
           Location    = $Rec.Location.City + ", " + $Rec.Location.State + ", " + $Rec.Location.CountryOrRegion
           Appname     = $Rec.AppDisplayName
           Resource    = $Rec.ResourceDisplayName
           Status      = $Status
           Correlation = $Rec.CorrelationId
           Interactive = $Rec.IsInteractive }
      $Report.Add($ReportLine) } 

function Show-Menu
{
     param (
        [string]$Title = 'Select role to request'
     )
     Clear-Host
     Write-Host "================ $Title ================`n"
    
     Write-Host "1: '1' Status on logins by number and status state."
     Write-Host "2: '2' List of Apps used."
     Write-Host "3: '3' Locations logins orignated from (successful and unsuccessful)."
     Write-Host "Q: Press 'Q' to quit. `n"
}

do
{
    Write-Host `r`n $Report.Count "sign-in audit records processed."
    Show-Menu
    $Userinput = Read-Host "Please make a selection"
    $schedule = New-Object Microsoft.Open.MSGraph.Model.AzureADMSPrivilegedSchedule
    $schedule.Type = "Once"
    $schedule.Duration="PT4H" #Change number 4 to the number of hourse wanted
    $schedule.StartDateTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    switch ($Userinput)
     {
        '1' {
            Clear-Host
            Write-Host `r`n $Report.Count "sign-in audit records processed."
            Write-Host `r`n "Status on logins by number and status state" 
            $Report | Group Status | Sort Count -Descending | Format-Table Count, Name -AutoSize
        } '2' {
            Clear-Host
            Write-Host `r`n $Report.Count "sign-in audit records processed."
            Write-Host `r`n "List of Apps used"
            $Report | Group AppName | Sort Count -Descending | Format-Table Count, Name -AutoSize
        } '3' {
            Clear-Host
            Write-Host `r`n $Report.Count "sign-in audit records processed."
            Write-Host `r`n "Locations logins orignated from (successful and unsuccessful)"
            $Report | Group Location | Sort Count -Descending | Format-Table Count, Name -AutoSize
        } 'q' {
            return
        }
     }
     pause
}
until ($Userinput -eq 'q')
