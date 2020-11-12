Connect-AzureAD
$User = Read-Host "Enter first name (or start of username) of user account"
$Users = Get-AzureADUser -SearchString $User
ForEach ($U in $Users) {
   If ($U.UserType -eq "Member") {
      $UserLastLogonDate = $Null
      Try {
         $UserObjectId = $U.ObjectId
         $UserLastLogonDate = (Get-AzureADAuditSignInLogs -Top 1  -Filter "userid eq '$UserObjectId' and status/errorCode eq 0").CreatedDateTime 
      }
      Catch {
         Write-Host "Can't read Azure Active Directory Sign in Logs"`n 
      }
      If ($Null -ne $UserLastLogonDate) {
         $LastSignInDate = Get-Date($UserLastLogonDate); $Days = New-TimeSpan($LastSignInDate)
         Write-Host "User" $U.DisplayName "last signed in on" $LastSignInDate "or" $Days.Days "days ago"`n 
      }
      Else { Write-Host "No Azure Active Directory sign-in data available for" $U.DisplayName "(" $U.Mail ")"`n }
   }
}
