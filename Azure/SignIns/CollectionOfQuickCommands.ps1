Connect-AzureAD -AccountId demolav@tvedt.one
Install-Module AzureADPreview -AllowClobber
uninstall-Module AzureAD


#Singel user last successfull
Get-AzureADAuditSignInLogs -Top 1 -Filter ("UserPrincipalName eq 'demolav@tvedt.one' and status/errorCode eq 0")  | Format-Table CreatedDateTime, UserDisplayName

#Singel user 5 last unsuccessfull
Get-AzureADAuditSignInLogs -Top 5 -Filter ("userPrincipalName eq 'demolav@tvedt.one' and status/errorCode ne 0") | select UserPrincipalName,RiskState,ClientAppUsed,IpAddress,{ $_.Location.City},{ $_.Location.CountryOrRegion},{ $_.Status.FailureReason}

#Singel user unsuccessfull since date
Get-AzureADAuditSignInLogs -Filter ("userPrincipalName eq 'demolav@tvedt.one' and createdDateTime gt 2020-09-20 and status/errorCode ne 0") | select UserPrincipalName,RiskState,ClientAppUsed,IpAddress,{ $_.Location.City},{ $_.Location.CountryOrRegion},{ $_.Status.FailureReason} | FT

#All users unsuccessfull since date:
Get-AzureADAuditSignInLogs -Filter ("createdDateTime gt 2020-09-20 and status/errorCode ne 0") | select UserPrincipalName,RiskState,ClientAppUsed,IpAddress,{ $_.Location.City},{ $_.Location.CountryOrRegion},{ $_.Status.FailureReason} | ft
