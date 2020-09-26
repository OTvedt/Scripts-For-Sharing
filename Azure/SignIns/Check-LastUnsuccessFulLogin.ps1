$User = Read-Host "Enter first name (or start of username) of user account"
$Users = Get-AzureADUser -SearchString $User
ForEach ($U in $Users) {
   If ($U.UserType -eq "Member") { #Change to Guest if you want to check guest instead of tenantes users
      $UserLastLogonDate = $Null
      Try {
         $UserObjectId = $U.ObjectId
         $UserLastLogonDate = (Get-AzureADAuditSignInLogs -Top 1  -Filter "userid eq '$UserObjectId' and status/errorCode ne 0").CreatedDateTime }
      Catch {
         Write-Host "Can't read Azure Active Directory Sign in Logs"`n }
      If ($UserLastLogonDate -ne $Null) {
         $LastSignInDate = Get-Date($UserLastLogonDate); $Days = New-TimeSpan($LastSignInDate)
         Write-Host "User" $U.DisplayName "last unsuccessful signed in on" $LastSignInDate "or" $Days.Days "days ago"`n -ForegroundColor Red }
      Else { Write-Host "No unsuccsessful Azure Active Directory sign-in data available for" $U.DisplayName "(" $U.Mail ")"`n }
     }}
